# typed: false
# frozen_string_literal: true

require("npc/base")
require("npc/located")
require("npc/operand")
require("npc/result")

module NPC
  module OperationLink
    extend T::Sig
    extend T::Helpers

    include Kernel

    abstract!

    sig { abstract.returns(T.nilable(Block)) }
    def block; end

    sig { abstract.returns(T.nilable(OperationLink)) }
    def prev_link; end

    sig { abstract.params(x: OperationLink).returns(T.nilable(OperationLink)) }
    def prev_link=(x); end

    sig { abstract.returns(T.nilable(OperationLink)) }
    def next_link; end

    sig { abstract.params(x: OperationLink).returns(T.nilable(OperationLink)) }
    def next_link=(x); end

    sig { returns(Block) }
    def block!
      T.must(block)
    end

    sig { returns(OperationLink) }
    def prev_link!
      T.must(prev_link)
    end

    sig { returns(OperationLink) }
    def next_link!
      T.must(next_link)
    end

    sig { returns(T.nilable(Operation)) }
    def prev_operation
      x = prev_link
      x if x.is_a?(Operation)
    end

    sig { returns(T.nilable(Operation)) }
    def next_operation
      x = next_link
      x if x.is_a?(Operation)
    end
  end

  ## Operations are stored in a circular doubly-linked list.
  ## This type sits at the root of the list, connecting the
  ## front of the list to the back.
  class OperationSentinel
    extend T::Sig
    include OperationLink

    sig { params(block: Block).void }
    def initialize(block)
      @block = T.let(block, Block)
      @prev_link = T.let(self, OperationLink)
      @next_link = T.let(self, OperationLink)
    end

    sig { override.returns(T.nilable(Block)) }
    attr_reader :block

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

  ## The base class for all operations in NPC.
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
        operands: T::Array[Operand],
        results: T::Array[Result],
        attributes: T::Hash[Symbol, T.untyped],
      ).void
    end
    def initialize(
      operands = [],
      results = [],
      attributes = {}
    )
      super()
      # @location  = T.let(location, Location)
      @operands   = T.let(operands, T::Array[Operands])
      @results    = T.let(results,  T::Array[AnyResult])
      @attributes = T.let(attributes, T::Hash[Symbol, T.untyped])

      @prev_link = T.let(nil, T.nilable(OperationLink))
      @next_link = T.let(nil, T.nilable(OperationLink))
    end

    ### Attributes

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :attributes

    sig { params(key: Symbol).returns(T.untyped) }
    def attribute(key)
      attributes.fetch(key)
    end
  
    sig { params(key: Symbol).returns(T::Boolean) }
    def attribute?(key)
      attributes.key?(key)
    end

    ### Operation Links

    sig { override.returns(T.nilable(Block)) }
    attr_reader :block

    sig { params(block: T.nilable(Block)).returns(T.nilable(Block)) }
    attr_writer :block

    sig { override.returns(T.nilable(OperationLink)) }
    attr_accessor :prev_link

    sig { override.returns(T.nilable(OperationLink)) }
    attr_accessor :next_link

    sig { returns(T::Boolean) }
    def in_block?
      block != nil
    end

    sig { params(prev: OperationLink).void }
    def insert_into_block!(prev)
      raise "operation already in block" if
        @block || @prev_link || @next_link

      @block = T.must(prev.block)
      @prev_link = prev
      @next_link = prev.next_link!

      @prev_link.next_link = self
      @next_link.prev_link = self
    end

    sig { void }
    def remove_from_block!
      raise "operation not in block" unless
        @block && @prev_link && @next_link

      @prev_link.next_link = @next_link
      @next_link.prev_link = @prev_link

      @block = nil
      @prev_link = nil
      @next_link = nil
    end

    sig { params(point: OperationLink).void }
    def move!(point)
      remove_from_block! if in_block?
      insert_into_block!(point)
    end

    # The region that this op is in.
    sig { returns(T.nilable(Region)) }
    def region
      block&.region
    end

    ### Dropping and Destruction of Operation

    sig { void }
    def drop!
      remove_from_block! if in_block?
      drop_operands!
      drop_uses!
    end

    # Clear all operands in this operation.
    sig { void }
    def drop_operands!
      operands.each(&:drop!)
    end

    # Drop all references to this operation's results.
    sig { void }
    def drop_uses!
      results.each(&:drop_uses!)
    end

    # Replace the uses of this operation's results with the results of a different operation.
    sig { params(other: Operation).void }
    def replace_uses!(other)
      # TODO: Need to check that the types line up.
      # TODO: Need to check that these ops are in the same block.
      results.each do |result|
        result.replace_uses!(other.results[result.index])
      end
    end

    # Drop this operator from the block, and replace it with another.
    # The new operation will be inserted where
    sig { params(other: Operation).void }
    def replace!(other)
      raise "op must be in a block to be replaced" unless in_block?
      # TODO: Need to check that the types are compatible.
      cursor = prev_link!
      remove_from_block!
      other.insert_into_block!(cursor)
      replace_uses!(other)
    end

    ### Attributes

    # sig { returns(Location) }
    # attr_reader :location

    ### Operands

    sig { returns(T::Array[Operand]) }
    attr_reader :operands

    sig { params(index: Integer).returns(Operand) }
    def operand(index)
      operands.fetch(index)
    end

    def operand_count
      operands.count
    end

    # Push a new operand onto the end of the operand array.
    sig { params(value: T.nilable(Value)).returns(Operand) }
    def new_operand(value = nil)
      operand = Operand.new(self, operands.length, value)
      operands << operand
      operand
    end

    ### Results

    sig { returns(T::Array[Result]) }
    attr_reader :results

    sig { params(index: Integer).returns(Result) }
    def result(index = 0)
      results.fetch(index)
    end
  
    sig { returns(Integer) }
    def result_count
      results.length
    end
  
    # Push a new result onto the end of the result array.
    sig { returns(Result) }
    def new_result
      result = Result.new(self, results.length)
      results << result
      result
    end

    ### Cloning and Copying

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
  end
end
