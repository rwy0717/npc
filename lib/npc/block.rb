# typed: strict
# frozen_string_literal: true

require("npc/argument")
require("npc/operation")
require("npc/block_operand")

module NPC
  module BlockLink
    extend T::Sig
    extend T::Helpers

    include Kernel

    abstract!

    sig { abstract.returns(T.nilable(Region)) }
    def parent_region; end

    sig { abstract.returns(T.nilable(BlockLink)) }
    def prev_link; end

    sig { abstract.params(x: BlockLink).returns(T.nilable(BlockLink)) }
    def prev_link=(x); end

    sig { abstract.returns(T.nilable(BlockLink)) }
    def next_link; end

    sig { abstract.params(x: BlockLink).returns(T.nilable(BlockLink)) }
    def next_link=(x); end

    sig { returns(Region) }
    def parent_region!
      T.must(parent_region)
    end

    sig { returns(T.nilable(Operation)) }
    def parent_operation
      parent_region&.parent_operation
    end

    sig { returns(Operation) }
    def parent_operation!
      parent_region!.parent_operation!
    end

    sig { returns(T.nilable(Block)) }
    def parent_block
      parent_operation&.parent_block
    end

    sig { returns(Block) }
    def parent_block!
      parent_operation!.parent_block!
    end

    sig { returns(BlockLink) }
    def prev_link!
      T.must(prev_link)
    end

    sig { returns(BlockLink) }
    def next_link!
      T.must(next_link)
    end

    sig { returns(T.nilable(Block)) }
    def prev_block
      x = prev_link
      x if x.is_a?(Block)
    end

    sig { returns(T.nilable(Block)) }
    def next_block
      x = next_link
      x if x.is_a?(Block)
    end

    sig { returns(Block) }
    def prev_block!
      T.must(prev_block)
    end

    sig { returns(Block) }
    def next_block!
      T.must(next_block)
    end
  end

  class BlockSentinel
    extend T::Sig
    include BlockLink

    sig { params(parent_region: Region).void }
    def initialize(parent_region)
      @parent_region = T.let(parent_region, Region)
      @prev_link = T.let(self, T.nilable(BlockLink))
      @next_link = T.let(self, T.nilable(BlockLink))
    end

    sig { override.returns(T.nilable(Region)) }
    attr_reader :parent_region

    sig { override.returns(T.nilable(BlockLink)) }
    attr_accessor :prev_link

    sig { override.returns(T.nilable(BlockLink)) }
    attr_accessor :next_link
  end

  # Iterator for operations in a block.
  class OperationsInBlock
    extend T::Sig
    extend T::Generic

    include Enumerable

    Elem = type_member { { fixed: Operation } }

    sig { params(block: Block).void }
    def initialize(block)
      @first = T.let(block.first_operation, T.nilable(Operation))
    end

    sig { override.params(proc: T.proc.params(arg0: Operation).returns(BasicObject)).returns(BasicObject) }
    def each(&proc)
      operation = T.let(@first, T.nilable(Operation))
      while operation
        n = operation.next_operation
        proc.call(operation)
        operation = n
      end
    end
  end

  # Iterator for the block-operands that use a given block.
  class BlockUses
    class << self
      extend T::Sig

      sig { params(block: Block).returns(BlockUses) }
      def of(block)
        BlockUses.new(block.first_use)
      end
    end

    extend T::Sig
    extend T::Generic

    include Enumerable

    Elem = type_member { { fixed: BlockOperand } }

    sig { params(root: T.nilable(BlockOperand)).void }
    def initialize(root)
      @root = T.let(root, T.nilable(BlockOperand))
    end

    sig { override.params(proc: T.proc.params(arg0: BlockOperand).returns(BasicObject)).returns(BasicObject) }
    def each(&proc)
      use = T.let(@root, T.nilable(BlockOperand))
      while use
        next_use = use.next_use
        proc.call(use)
        use = next_use
      end
    end
  end

  # Iterator for the operations that use a given block as a block-operand.
  class BlockUsers
    class << self
      extend T::Sig

      sig { params(block: Block).returns(BlockUsers) }
      def of(block)
        BlockUsers.new(block.first_use)
      end
    end

    extend T::Sig
    extend T::Generic

    include Enumerable

    Elem = type_member { { fixed: Operand } }

    sig { params(root: T.nilable(BlockOperand)).void }
    def initialize(root)
      @uses = T.let(BlockUses.new(root), BlockUses)
    end

    sig { override.params(proc: T.proc.params(arg0: Operation).returns(BasicObject)).returns(BasicObject) }
    def each(&proc)
      @uses.each do |use|
        user = use.parent_operation
        proc.call(user) if user
      end
    end
  end

  ## A basic block in the CFG. Blocks belongs to a region, and contain an ordered list of operations.
  class Block
    extend T::Sig
    include BlockLink

    class << self
      extend T::Sig

      # Construct a new block with arguments.
      sig { params(arg_tys: T::Array[Type]).returns(Block) }
      def with_args(arg_tys)
        Block.new(arg_tys)
      end

      # Construct a new block in a region.
      sig { params(region: Region, arg_tys: T::Array[Type]).returns(Block) }
      def in_region(region, arg_tys = [])
        block = Block.new(arg_tys)
        block.insert_into_region!(region.back)
        block
      end
    end

    sig do
      params(
        argument_types: T::Array[Type],
      ).void
    end
    def initialize(argument_types = [])
      @parent_region = T.let(nil, T.nilable(Region))
      @prev_link = T.let(nil, T.nilable(BlockLink))
      @next_link = T.let(nil, T.nilable(BlockLink))
      @arguments = T.let([], T::Array[Argument])
      @sentinel = T.let(OperationSentinel.new(self), OperationSentinel)
      @first_use  = T.let(nil, T.nilable(BlockOperand))
      argument_types.each do |type|
        add_argument(type)
      end
    end

    ### Accessing the region that this block is a member of.

    ## Get the region that this block is a member of. Nil if this block is disconnected.
    sig { override.returns(T.nilable(Region)) }
    attr_reader :parent_region

    sig { returns(T::Boolean) }
    def in_region?
      @parent_region != nil
    end

    ## Get the region that this block is a member of. Throws if this block is disconnected.
    sig { returns(Region) }
    def parent_region!
      T.must(@parent_region)
    end

    ## Get the previous block in the region's linked list of blocks.
    sig { override.returns(T.nilable(BlockLink)) }
    attr_accessor :prev_link

    ## Get the next block in the region's linked list of blocks.
    sig { override.returns(T.nilable(BlockLink)) }
    attr_accessor :next_link

    ## Insert this block into a region.
    sig { params(cursor: BlockLink).returns(T.self_type) }
    def insert_into_region!(cursor)
      raise "block already in region" if
        @parent_region || @prev_link || @next_link

      @parent_region = T.must(cursor.parent_region)
      @prev_link = cursor
      @next_link = cursor.next_link!

      @prev_link.next_link = self
      @next_link.prev_link = self

      self
    end

    ## Remove this block from it's region.
    sig { returns(T.self_type) }
    def remove_from_region!
      raise "block not in region" unless
        @parent_region && @prev_link && @next_link

      @prev_link.next_link = @next_link if @prev_link
      @next_link.prev_link = @prev_link if @next_link

      @parent_region = nil
      @prev_link = nil
      @next_link = nil

      self
    end

    ## Move this block to a new region.
    sig { params(cursor: T.nilable(BlockLink)).void }
    def move!(cursor)
      remove_from_region! if in_region?
      insert_into_region!(cursor) if cursor
    end

    ## If this block is in a region, remove it.
    sig { void }
    def drop!
      remove_from_region! if in_region?
    end

    ### Arguments

    ## Get the block's argument array.
    sig { returns(T::Array[Argument]) }
    attr_reader :arguments

    sig { params(index: Integer).returns(Argument) }
    def argument(index = 0)
      arguments.fetch(index)
    end

    ## Append a new argument to this block. Returns the new argument.
    sig { params(type: T.nilable(Type)).returns(Argument) }
    def add_argument(type)
      a = Argument.new(self, type)
      arguments << a
      a
    end

    sig { params(argument: Argument).void }
    def append_argument!(argument)
      if argument.parent_block
        raise "argument already owned by block"
      end

      argument.parent_block = self
      arguments.append(argument)
    end

    sig { params(argument: Argument).void }
    def delete_argument!(argument)
      if argument.parent_block != self
        raise "argument not owned by this block"
      end

      arguments.delete(argument)
      argument.parent_block = nil
    end

    ### Operation Management

    ## The link before the first block. An insertion point for prepending operations.
    sig { returns(OperationLink) }
    def front
      @sentinel
    end

    ## The link after the last block. An insertion point for appending operations.
    sig { returns(OperationLink) }
    def back
      @sentinel.prev_link
    end

    sig { returns(OperationLink) }
    def before_back
      back.prev_link!
    end

    ## The link before the block's terminating operation. If the last operator
    ## is not a terminator, just return the last operation.
    sig { returns(OperationLink) }
    def before_terminator
      op = back
      op.is_a?(Terminator) ? op.prev_link! : op
    end

    ## The first operation in this block. Nil if this block is empty.
    sig { returns(T.nilable(Operation)) }
    def first_operation
      @sentinel.next_operation
    end

    sig { returns(Operation) }
    def first_operation!
      @sentinel.next_operation!
    end

    ## The last operation in this block. Nil if this block is empty.
    sig { returns(T.nilable(Operation)) }
    def last_operation
      @sentinel.prev_operation
    end

    sig { returns(Operation) }
    def last_operation!
      @sentinel.prev_operation!
    end

    ## The operation that terminates this block
    ## Nil if the block is empty, or if the last operation is not a Terminator.
    sig { returns(T.nilable(Operation)) }
    def terminator
      op = back
      op if op.is_a?(Operation) && op.is_a?(Terminator)
    end

    # The operation that terminates this block
    # Nil if the block is empty, or if the last operation is not a Terminator.
    sig { returns(T.nilable(Operation)) }
    def terminator!
      T.must(terminator)
    end

    # Does this block contain any operations?
    sig { returns(T::Boolean) }
    def empty?
      @sentinel.next_link == @sentinel
    end

    # Does this block contain exactly one operation?
    sig { returns(T::Boolean) }
    def one_operation?
      n = @sentinel.next_link
      p = @sentinel.prev_link
      n != p && n.next_link == p
    end

    # An enumerable that walks the operations in this block.
    sig { returns(OperationsInBlock) }
    def operations
      OperationsInBlock.new(self)
    end

    # Prepend an operation to this block.
    # The operation must not be in a block.
    sig { params(operation: Operation).returns(Block) }
    def prepend_operation!(operation)
      operation.insert_into_block!(front)
      self
    end

    # Append an operation.
    # The operation must not be in a block.
    sig { params(operation: Operation).returns(Block) }
    def append_operation!(operation)
      operation.insert_into_block!(back)
      self
    end

    sig { params(operation: Operation).returns(Block) }
    def remove_operation!(operation)
      raise "operation is not a child of this block" if self != operation.parent_block

      operation.remove_from_block!
      self
    end

    # Move the operations from another block into this block, at the front.
    sig { params(block: Block).returns(Block) }
    def prepend_operations_from_block!(block)
      block.operations.each do |operation|
        operation.move!(front)
      end
      self
    end

    # Move the operations from another block into this block, at the back.
    sig { params(block: Block).returns(Block) }
    def append_operations_from_block!(block)
      block.operations.each do |operation|
        operation.move!(back)
      end
      self
    end

    #
    # Uses
    #

    sig { returns(T.nilable(BlockOperand)) }
    attr_accessor :first_use

    sig { returns(T::Boolean) }
    def unused?
      @first_use.nil?
    end

    sig { returns(T::Boolean) }
    def used?
      @first_use != nil
    end

    sig { returns(T::Boolean) }
    def used_once?
      if @first_use
        @first_use.next_use.nil?
      else
        false
      end
    end

    # An enumerable of the BlockOperands that use this Block.
    sig { returns(BlockUses) }
    def uses
      BlockUses.new(@first_use)
    end

    # An Enumerable of the Operations that use this Block as a BlockOperand.
    sig { returns(BlockUsers) }
    def users
      BlockUsers.new(@first_use)
    end

    #
    # Predecessor and Successor Blocks
    #

    # The blocks that branch to this block.
    sig { returns(T::Array[Block]) }
    def predecessors
      preds = []
      use = T.let(@first_use, T.nilable(BlockOperand))
      while use
        block = use.parent_operation&.parent_block
        preds << block if block
        use = use.next_use
      end
      preds
    end

    sig { returns(T::Boolean) }
    def any_predecessors?
      !@first_use.nil?
    end

    sig { returns(T::Boolean) }
    def no_predecessors?
      @first_use.nil?
    end

    # Get the successor-blocks (blocks that come after this, in execution order).
    # If this block has a terminator operation, then any block-operands for that terminator are considered successors.
    sig { returns(T::Array[Block]) }
    def successors
      terminator&.successors || []
    end

    sig { returns(ArrayIterator[Block]) }
    def successors_iter
      ArrayIterator.new(successors)
    end

    sig { returns(T::Boolean) }
    def any_successors?
      t = terminator
      t&.block_operands&.any? ? true : false
    end

    sig { returns(T::Boolean) }
    def no_successors?
      t = terminator
      return true unless t

      t.block_operands.none?
    end

    #
    # Printing
    #

    sig { returns(String) }
    def inspect
      to_s
    end

    sig { returns(String) }
    def to_s
      id = format("%016x", object_id)
      "#<#{self.class.name}:0x#{id}>"
    end

    sig { void }
    def dump
      Printer.print_block(self)
    end
  end
end
