# typed: true
# frozen_string_literal: true

module NPC
  class OperationsInRegion
    extend T::Sig
    extend T::Generic

    include Enumerable

    Elem = type_member(fixed: Operation)

    sig { params(region: Region).void }
    def initialize(region)
      @region = T.let(region, Region)
    end

    sig { returns(Region) }
    attr_reader :region

    sig { override.params(proc: T.proc.params(arg0: Operation).returns(BasicObject)).returns(BasicObject) }
    def each(&proc)
      @region.blocks.each do |block|
        block.operations.each do |operation|
          proc.call(operation)
        end
      end
    end
  end

  # Iterator for blocks in region.
  class BlocksInRegion
    extend T::Sig
    extend T::Generic

    include Enumerable

    Elem = type_member(fixed: Block)

    sig { params(region: Region).void }
    def initialize(region)
      @next = T.let(region.first_block, T.nilable(Block))
    end

    sig { override.params(proc: T.proc.params(arg0: Block).returns(BasicObject)).returns(BasicObject) }
    def each(&proc)
      block = T.let(@next, T.nilable(Block))
      while block
        n = block.next_block
        proc.call(block)
        block = n
      end
    end
  end

  class Region
    extend T::Sig

    class << self
      extend T::Sig

      # sig { params(op: T.nilable(Operation), block: T.nilable(Block)).returns(Region) }
      # def with_block(block = Block.new([]))
      #   block ||= Block.new(arguments: [])
      #   Region.new(op, block, [blocks])
      # end
    end

    sig do
      params(
        operation: T.nilable(Operation),
      ).void
    end
    def initialize(
      operation: nil # The parent operation of this region.
    )
      @operation = T.let(operation, T.nilable(Operation))
      @block_root = T.let(BlockSentinel.new(self), BlockSentinel)
    end

    # The sentinel node of the linked list of blocks in this region.
    sig { returns(BlockSentinel) }
    attr_reader :sentinel

    # The link before the first block.
    # Can be used as an insertion point for prepending blocks.
    # Works even if the region is empty.
    sig { returns(BlockLink) }
    def beginning
      sentinel
    end

    # The link after the last block.
    # Can be used as an insertion point for appending blocks.
    # Works even if the region is empty.
    sig { returns(BlockLink) }
    def end
      sentinel.prev_link!
    end

    sig { returns(T.nilable(Block)) }
    def first_block
      sentinel.next_block
    end

    sig { returns(T.nilable(Block)) }
    def last_block
      sentinel.prev_block
    end

    # The parent/containing operation of this region.
    sig { returns(T.nilable(Operation)) }
    attr_reader :operation

    sig { returns(Operation) }
    def operation!
      T.must(operation)
    end

    # The region that contains this region.
    sig { returns(T.nilable(Region)) }
    def parent_region
      operation&.region
    end

    sig { returns(Region) }
    def parent_region!
      T.must(parent_region)
    end

    ## Block Management

    sig { returns(T::Boolean) }
    def empty?
      sentinel.next_block == sentinel
    end

    sig { returns(T.nilable(Block)) }
    def first_block
      sentinel.next_block
    end
   
    sig { returns(T.nilable(Block)) }
    def last_block
      sentinel.prev_block
    end

    sig { returns(BlocksInRegion) }
    def blocks
      BlocksInRegion.new(@first_block)
    end

    ## Insert a block into this region.
    sig { params(block: Block).returns(Region) }
    def append_block(block)
      block.insert_into_region!(beginning)
      self
    end

    ## Insert a block at the beginning of this region.
    sig { params(block: Block).returns(Block) }
    def prepend_block(block)
      block.insert_into_region!(beginning)
      block
    end
  
    ## Remove a block from this region. Returns the removed block.
    sig { params(block: Block).returns(Block) }
    def remove_block(block)
      raise "block is not a child of this region" if self != block.region
      block.remove_from_region!
      block
    end

    ### Region Arguments

    ## Arguments of this region. Derived from the arguments of the entry block.
    sig { returns(T::Array[Argument]) }
    def arguments
      first_block&.arguments || []
    end

    ## Operations in this region

    # An iterator that visits all operations in a region.
    sig { returns(OperationsInRegion) }
    def operations
      OperationsInRegion.new(self)
    end
  end
end
