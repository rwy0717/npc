# typed: false
# frozen_string_literal: true

require("npc/base")
require("npc/located")
require("npc/operand")
require("npc/result")

module NPC
  # # @api private
  # # An empty array of operands.
  # # The default operand-array, when an operation has operands.
  # NO_OPERANDS       = T.let([].freeze, T::Array[Operand])

  # # @api private
  # # An empty array of results.
  # # The default result-array, when an operation has no results.
  # NO_RESULTS        = T.let([].freeze, T::Array[Result])

  # # @api private
  # # An empty array of attributes.
  # # The default attribute-hash, when an operation has no attributes.
  # NO_ATTRIBUTES = T.let({}.freeze, T::Hash[Symbol, T.untyped])

  # # @api private
  # # An empy array of block-operands.
  # # The default block-operand-array, when an operand has no block-operands.
  # NO_BLOCK_OPERANDS = T.let([].freeze, T::Array[BlockOperand])

  # # @api private
  # # An empty array of regions.
  # # The default region-array, when an operation has no regions.
  # NO_REGIONS        = T.let([].freeze, T::Array[Region])

  # @api private
  # The interface for the intrusive-linked-list that chains together all operations in a block.
  module OperationLink
    extend T::Sig
    extend T::Helpers

    include Kernel

    abstract!

    sig { abstract.returns(T.nilable(Block)) }
    def parent_block; end

    sig { abstract.returns(T.nilable(OperationLink)) }
    def prev_link; end

    sig { abstract.params(x: OperationLink).returns(T.nilable(OperationLink)) }
    def prev_link=(x); end

    sig { abstract.returns(T.nilable(OperationLink)) }
    def next_link; end

    sig { abstract.params(x: OperationLink).returns(T.nilable(OperationLink)) }
    def next_link=(x); end

    sig { returns(Block) }
    def parent_block!
      T.must(parent_block)
    end

    # The parent region that this operation-link is attached to.
    # Nil if this operation-link is not in a region.
    sig { returns(T.nilable(Region)) }
    def parent_region
      parent_block&.parent_region
    end

    # The parent region that this operation-link is in.
    # Throws if this operation-link is not in a region.
    sig { returns(Region) }
    def parent_region!
      T.must(parent_region)
    end

    # The operation, that holds the region, that holds the block, that holds this operation-link.
    sig { returns(Region) }
    def parent_operation
      parent_region&.parent_operation
    end

    sig { returns(Operation) }
    def parent_operation!
      T.must(parent_operation)
    end

    # The root of the program, the greatest ancestor of this operation.
    sig { returns(T.nilable(Operation)) }
    def root_operation
      op = self
      op = op.parent_operation while op.parent_operation
      op
    end

    sig { returns(OperationLink) }
    def prev_link!
      T.must(prev_link)
    end

    sig { returns(OperationLink) }
    def next_link!
      T.must(next_link)
    end

    # Get the previous operation in the block.
    # Nil if this operation is not in a block, or if this is the first operation in the block.
    sig { returns(T.nilable(Operation)) }
    def prev_operation
      x = prev_link
      x if x.is_a?(Operation)
    end

    # Get the next operation in the block.
    # Nil if this operation is not in a block, or if this is the last operation in the block.
    sig { returns(T.nilable(Operation)) }
    def next_operation
      x = next_link
      x if x.is_a?(Operation)
    end
  end

  # @api private
  # Operations are stored in a circular doubly-linked list.
  # This type sits at the root of the list, connecting the
  # front of the list to the back.
  class OperationSentinel
    extend T::Sig
    include OperationLink

    sig { params(parent_block: Block).void }
    def initialize(parent_block)
      @parent_block = T.let(parent_block, Block)
      @prev_link = T.let(self, OperationLink)
      @next_link = T.let(self, OperationLink)
    end

    sig { override.returns(T.nilable(Block)) }
    attr_reader :parent_block

    sig { override.returns(OperationLink) }
    attr_accessor :prev_link

    sig { override.returns(OperationLink) }
    attr_accessor :next_link
  end

  AttributeHash = T.type_alias { T::Hash[Symbol, T.untyped] }

  class OperandInfo < T::Struct
    const :name, Symbol
    const :index, Integer
    const :type, Class
  end

  class ResultInfo < T::Struct
    const :name, Symbol
    const :index, Integer
    const :type, Class
  end

  class Signature < T::Struct
    const :operands, T::Hash[Symbol, OperandInfo]
    const :operand_tail, T::Array[OperandInfo]
  end

  class SignatureBuilder
    extend T::Sig
    extend T::Helpers

    sig { void }
    def initialize
      @operand_list = T.let([], T::Array[OperandInfo])
      @result_list  = T.let([], T::Array[ResultInfo])
    end

    sig { params(name: Symbol).returns(T.self_type) }
    def operand(name)
      @operand_list << OperandInfo.new(
        type: Operand,
        name: name,
        index: @operand_list.length,
      )
      self
    end

    sig { params(name: Symbol).returns(T.self_type) }
    def operand_array(name)
      @operand_list << OperandInfo.new(
        type: OperandArray,
        name: name,
        index: @operand_list.length,
      )
      self
    end

    sig { params(name: Symbol).returns(T.self_type) }
    def result(name)
      @result_list << ResultInfo.new(
        type: Result,
        name: name,
        index: @result_list.length,
      )
      self
    end

    sig { returns(T::Array[OperandInfo]) }
    attr_reader :operand_list

    sig { returns(T::Array[ResultInfo]) }
    attr_reader :result_list
  end

  module Define
    extend T::Sig
    extend T::Helpers

    module ClassMethods
      extend T::Sig
      extend T::Helpers
      include Kernel

      sig do
        params(
          proc: T.proc.bind(SignatureBuilder).void
        ).void
      end
      def define(&proc)
        builder = SignatureBuilder.new
        builder.instance_eval(&proc)
        p(builder)
        builder.operand_list.each do |operand_info|
          define_operand_accessors(operand_info)
        end
      end

      sig { params(operand_info: OperandInfo).void }
      def define_operand_accessors(operand_info)
        name = operand_info.name

        define_method(name.to_s) do
          operands[index].value
        end

        define_method("#{name}=") do |value|
          raise "must be value" unless value.is_a?(Value)
          operands[index].value = value
        end

        define_method("#{name}_operand") do
          operands[index]
        end

        define_method("#{name}_operand_info") do
          self.class.operand_table[name]
        end
      end
    end

    mixes_in_class_methods(ClassMethods)
  end

  # The base class for all operations in NPC.
  class Operation
    extend T::Sig
    extend T::Helpers
    include Define
    include OperationLink

    module ClassMethods
      extend T::Sig
      extend T::Helpers

      def operand_table
        @operand_table = T.let(@operand_table, T.nilable(T::Hash[Symbol, OperandInfo]))
        @operand_table ||= {}
      end

      sig do
        params(
          name: Symbol
        ).void
      end
      def operand(name)
        index = operand_table.length
        info = OperandInfo.new(index: index)
        operand_table[name] = info
      end
    end

    sig do
      params(
        results: T::Array[Type],
        operands: T::Array[T.nilable(Value)],
        block_operands: T::Array[T.nilable(Block)],
        attributes: T::Hash[Symbol, T.untyped],
        successors: T::Array[T.nilable(Block)],
        regions: Integer,
        loc: T.nilable(Location),
      ).void
    end
    def initialize(
      results: [],
      operands: [],
      block_operands: [],
      attributes: {},
      successors: [],
      regions: 0,
      loc: nil
    )
      @operands = T.let([], T::Array[Operand])
      operands.each do |value|
        new_operand(value)
      end

      @block_operands = T.let([], T::Array[BlockOperand])
      block_operands.each do |block|
        new_block_operand(block)
      end

      @results = T.let([], T::Array[Result])
      results.each do |type|
        new_result(type)
      end

      @regions = T.let([], T::Array[Region])
      regions.times do
        @regions.push(Region.new)
      end

      @attributes = T.let(attributes, T::Hash[Symbol, T.untyped])

      @parent_block = T.let(nil, T.nilable(Block))
      @prev_link = T.let(nil, T.nilable(OperationLink))
      @next_link = T.let(nil, T.nilable(OperationLink))

      @location  = T.let(loc, T.nilable(Location))
    end

    sig { overridable.returns(String) }
    def operator_name
      self.class.name
    end

    # @!group Attributes

    # Get the underlying hash of attributes for this operation.
    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :attributes

    # Fetch an attribute by name. Throws if the attribute is not defined.
    sig { params(key: Symbol).returns(T.untyped) }
    def attribute(key)
      attributes.fetch(key)
    end

    # Is the symbol an attribute on this operation?
    sig { params(key: Symbol).returns(T::Boolean) }
    def attribute?(key)
      attributes.key?(key)
    end

    # @!group Block Operands / Successor Regions

    # The underlying block-operands array of this op.
    # Block-operands are the potential targets of branching control flow operations.
    sig { returns(T::Array[BlockOperand]) }
    attr_reader :block_operands

    # Push a new block-operand onto the end of the block-operand array.
    sig { params(target: T.nilable(Block)).returns(BlockOperand) }
    def new_block_operand(target = nil)
      block_operand = BlockOperand.new(self, block_operands.length, target)
      block_operands << block_operand
      block_operand
    end

    # The blocks that are reachable from this op.
    # If this operation is not a terminator, the list of successors must be empty.
    sig { returns(T::Array[Block]) }
    def successors
      block_operands.map(&:get).compact
    end

    sig { returns(ArrayIterator[Block]) }
    def successors_iter
      ArrayIterator.new(successors)
    end

    # @!group Regions

    # The regions inside this operations.
    sig { returns(T::Array[Region]) }
    attr_reader :regions

    # Get an inner region by index.
    sig { params(index: Integer).returns(Region) }
    def region(index)
      @regions.fetch(index)
    end

    # @!group Parent Block, Next/Prev Operation in Block

    # Get the block that this operation is in.
    # Nil if this operation is not inserted into a block.
    sig { override.returns(T.nilable(Block)) }
    attr_reader :parent_block

    sig { returns(T.nilable(Region)) }
    def parent_region
      @parent_block&.parent_region
    end

    # @api private
    # The previous object in the block.
    # Either the previous operation, or the root sentinel node if this is the first operation.
    # @see #prev_operation
    sig { override.returns(T.nilable(OperationLink)) }
    attr_accessor :prev_link

    # @api private
    # The next element in the block.
    # Either the next op, or the root sentinel node if this is the last operation.
    # @see #next_operation
    sig { override.returns(T.nilable(OperationLink)) }
    attr_accessor :next_link

    # True if this operation is in the given block.
    # If no block is given, true if this operation is in any block.
    sig { params(block: T.nilable(Block)).returns(T::Boolean) }
    def in_block?(block = nil)
      if block
        @parent_block.equal?(block)
      else
        !@parent_block.nil?
      end
    end

    # Insert this operation into a block.
    # Will fail if already in block.
    sig { params(prev: OperationLink).returns(T.self_type) }
    def insert_into_block!(prev)
      raise "operation already in block" if
        @parent_block || @prev_link || @next_link

      @parent_block = prev.parent_block!
      @prev_link = prev
      @next_link = prev.next_link!

      @prev_link.next_link = self
      @next_link.prev_link = self

      self
    end

    # Remove this operation from it's block.
    # Will fail if this operation is not in a block.
    sig { returns(T.self_type) }
    def remove_from_block!
      raise "operation not in block" unless
        @parent && @prev_link && @next_link

      @prev_link.next_link = @next_link
      @next_link.prev_link = @prev_link

      @parent = nil
      @prev_link = nil
      @next_link = nil

      self
    end

    # Remove this operation from it's current block (if applicable),
    # and insert it into a location after the given point.
    sig { params(point: OperationLink).void }
    def move!(point)
      remove_from_block! if in_block?
      insert_into_block!(point)
    end

    # @!group Operands

    # Access the underlying array of operands for
    sig { returns(T::Array[Operand]) }
    attr_reader :operands

    # Get an operand by index. Throws if index is out of bounds.
    sig { params(index: Integer).returns(Operand) }
    def operand(index)
      operands.fetch(index)
    end

    # The number of operands this operation has.
    def operand_count
      operands.count
    end

    # Get the value of an operand.
    sig { params(index: Integer).returns(T.nilable(Value)) }
    def operand_value(index)
      operand(index).get
    end

    # Get the value of an operand. Throws if the operand is not set.
    sig { params(index: Integer).returns(T.nilable(Value)) }
    def operand_value!(index)
      operand(index).get!
    end

    # Set the value of an operand.
    sig { params(index: Integer, value: T.nilable(Value)).void }
    def set_operand_value!(index, value)
      operand(index).reset!(value)
    end

    # sig { params(values: T::Array[Value]).void }
    # def set_operands!(values)
    #   operands.each_with_index do |values|
    #   end
    # end

    # Push a new operand onto the end of the operand array.
    sig { params(target: T.nilable(Value)).returns(Operand) }
    def new_operand(target = nil)
      operand = Operand.new(self, operands.length, target)
      operands << operand
      operand
    end

    # @!group Results

    # Access the underlying array of results for this operation.
    sig { returns(T::Array[Result]) }
    attr_reader :results

    # Access a result by index. Throws if index is out of range.
    sig { params(index: Integer).returns(Result) }
    def result(index = 0)
      results.fetch(index)
    end

    # The number of results this operation has.
    sig { returns(Integer) }
    def result_count
      results.length
    end

    # Push a new result onto the end of the result array.
    sig { params(type: Type).returns(Result) }
    def new_result(type)
      result = Result.new(self, results.length, type)
      results << result
      result
    end

    # @!group Uses

    # Replace the uses of this operation's results with the results of a different operation.
    sig { params(other: Operation).void }
    def replace_uses!(other)
      if results.length != other.results.length
        raise "cannot replace the uses of an op with an op with a different number of results"
      end

      unless parent.equal?(other.parent)
        raise "cannot replace the uses of an op with an op from a different block"
      end

      results.each do |result|
        result.replace_uses!(other.results.fetch(result.index))
      end
    end

    # Drop this operator from the block, and replace it with another.
    # The new operation will be inserted where the
    sig { params(other: Operation).void }
    def replace!(other)
      raise "op must be in a block to be replaced" unless in_block?

      cursor = prev_link!
      remove_from_block!
      other.insert_into_block!(cursor)
      replace_uses!(other)
    end

    # Drop all references to this operation's results.
    sig { void }
    def drop_uses!
      results.each(&:drop_uses!)
    end

    # @!group Dropping and Destruction of Operation

    # Drop this operation. Remove it from the block, clear it's inputs, and drop all it's uses.
    sig { void }
    def drop!
      remove_from_block! if in_block?
      drop_operands!
      drop_block_operands!
      drop_uses!
    end

    # Drop this operation. Throws if the value has any uses.
    sig { void }
    def erase!
      raise "cannot erase an operation that is used" if used?
      drop!
    end

    # Clear all operands in this operation.
    sig { void }
    def drop_operands!
      operands.each(&:drop!)
    end

    # Drop all the block-operands in this operation.
    sig { void }
    def drop_block_operands!
      block_operands.each(&:drop!)
    end

    # @!group Cloning and Copying

    # Deep copy of the operand array into another operation.
    sig { params(operation: Operation).returns(T::Array[Operand]) }
    def copy_operands_into(operation)
      operands.map { |operand| operand.copy_into(operation) }
    end

    # Deep copy of the results into another operation. Will have no uses.
    sig { params(operation: Operation).returns(T::Array[Result]) }
    def copy_results_into(operation)
      results.map { |result| result.copy_into(operation) }
    end

    # Deep copy of this operation.
    sig { returns(T.self_type) }
    def copy
      operation = dup
      copy_operands_into(operation)
      copy_results_into(operation)
      operation
    end

    # @!section validation

    sig { returns(T::Boolean) }
    def verify
      self.class.included_modules.each do |ancestor|
        next unless ancestor.is_a?(OperationVerifier)
        valid = ancestor.verify(self)
        unless valid
          return false
        end
      end

      true
    end

    sig { returns(String) }
    def to_s
      io = StringIO.new
      Printer.print_operation(self, out: io)
      io.string
    end

    sig { returns(String) }
    def inspect
      "<operation:#{object_id}>"
    end
  end
end
