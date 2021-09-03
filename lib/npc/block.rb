# typed: strict
# frozen_string_literal: true

require("npc/argument")
require("npc/base")
require("npc/operation")

module NPC
  module BlockLink
    extend T::Sig
    extend T::Helpers

    include Kernel

    abstract!

    sig { abstract.returns(T.nilable(Region)) }
    def region; end

    sig { abstract.returns(T.nilable(BlockLink)) }
    def prev_link; end

    sig { abstract.params(x: BlockLink).returns(T.nilable(BlockLink)) }
    def prev_link=(x); end

    sig { abstract.returns(T.nilable(BlockLink)) }
    def next_link; end

    sig { abstract.params(x: BlockLink).returns(T.nilable(BlockLink)) }
    def next_link=(x); end

    sig { returns(Region) }
    def region!
      T.must(region)
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

    sig { params(region: Region).void }
    def initialize(region)
      @region = T.let(region, Region)
      @prev_link = T.let(self, T.nilable(BlockLink))
      @next_link = T.let(self, T.nilable(BlockLink))
    end

    sig { override.returns(T.nilable(Region)) }
    attr_reader :region

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

    Elem = type_member(fixed: Operation)

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

  ## A basic block in the CFG. Blocks belongs to a region, and contain an ordered list of operations.
  class Block < Value
    extend T::Sig
    include BlockLink

    class << self
      extend T::Sig

      # Construct a new block with arguments.
      sig { params(arg_tys: T::Array[Type]).returns(Block) }
      def with_args(arg_tys)
        Block.new(argument_types: arg_tys)
      end

      # Construct a new block in a region.
      sig { params(region: Region, arg_tys: T::Array[Type]).returns(Block) }
      def in_region(region, arg_tys = [])
        block = Block.new(argument_types: arg_tys)
        block.insert_into_region!(region.back)
        block
      end
    end

    sig do
      params(
        argument_types: T::Array[Type],
      ).void
    end
    def initialize(argument_types: [])
      super()

      @region     = T.let(nil, T.nilable(Region))
      @prev_link  = T.let(nil, T.nilable(BlockLink))
      @next_link  = T.let(nil, T.nilable(BlockLink))
      @arguments  = T.let([], T::Array[Argument])
      @sentinel   = T.let(OperationSentinel.new(self), OperationSentinel)

      argument_types.each do |type|
        add_argument(type)
      end
    end

    ### Accessing the region that this block is a member of.

    ## Get the region that this block is a member of. Nil if this block is disconnected.
    sig { override.returns(T.nilable(Region)) }
    attr_reader :region

    sig { returns(T::Boolean) }
    def in_region?
      @region != nil
    end

    ## Get the region that this block is a member of. Throws if this block is disconnected.
    sig { returns(Region) }
    def region!
      T.must(@region)
    end

    ## Get the previous block in the region's linked list of blocks.
    sig { override.returns(T.nilable(BlockLink)) }
    attr_accessor :prev_link

    ## Get the next block in the region's linked list of blocks.
    sig { override.returns(T.nilable(BlockLink)) }
    attr_accessor :next_link

    ## Insert this block into a region.
    sig { params(cursor: BlockLink).void }
    def insert_into_region!(cursor)
      raise "block already in region" if
        @region || @prev_link || @next_link

      @region = T.must(cursor.region)
      @prev_link = cursor
      @next_link = cursor.next_link!

      @prev_link.next_link = self
      @next_link.prev_link = self
    end

    ## Remove this block from it's region.
    sig { void }
    def remove_from_region!
      raise "block not in region" unless
        @region && @prev_link && @next_link

      @prev_link.next_link = @next_link if @prev_link
      @next_link.prev_link = @prev_link if @next_link

      @region    = nil
      @prev_link = nil
      @next_link = nil
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

    ## Append a new argument to this block. Returns the new argument.
    sig { params(type: Type).returns(Argument) }
    def add_argument(type)
      i = arguments.length
      a = Argument.new(self, i, type)
      arguments << a
      a
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

    ## The first operation in this block. Nil if this block is empty.
    sig { returns(T.nilable(Operation)) }
    def first_operation
      @sentinel.next_operation
    end

    ## The last operation in this block. Nil if this block is empty.
    sig { returns(T.nilable(Operation)) }
    def last_operation
      @sentinel.prev_operation
    end

    ## Does this block contain any operations?
    sig { returns(T::Boolean) }
    def empty?
      @sentinel.next_link == @sentinel
    end

    ## An enumerable that walks the operations in this block.
    sig { returns(OperationsInBlock) }
    def operations
      OperationsInBlock.new(self)
    end

    sig { params(operation: Operation).returns(Block) }
    def prepend_operation!(operation)
      operation.insert_into_block!(front)
      self
    end

    sig { params(operation: Operation).returns(Block) }
    def append_operation!(operation)
      operation.insert_into_block!(back)
      self
    end

    sig { params(operation: Operation).returns(Block) }
    def remove_operation!(operation)
      raise "operation is not a child of this block" if self != operation.block
      operation.remove_from_block!
      self
    end

    sig { returns(T.nilable(Operation)) }
    def terminator
      # TODO!
      nil
    end
  end

  class Blocks
    extend T::Sig
    extend T::Helpers
  end
end
