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

    sig { params(parent_operation: T.nilable(Operation)).void }
    def initialize(parent_operation = nil)
      @parent_operation = T.let(parent_operation, T.nilable(Operation))
      @sentinel = T.let(BlockSentinel.new(self), BlockSentinel)
    end

    # The parent/containing operation of this region.
    sig { returns(T.nilable(Operation)) }
    attr_reader :parent_operation

    sig { returns(Operation) }
    def parent_operation!
      T.must(@parent_operation)
    end

    sig { returns(T.nilable(Block)) }
    def parent_block
      parent_operation&.parent_block
    end

    sig { returns(Block) }
    def parent_block!
      parent_operation!.parent_block!
    end

    # The region that contains this region.
    sig { returns(T.nilable(Region)) }
    def parent_region
      parent_block&.parent_region
    end

    sig { returns(Region) }
    def parent_region!
      parent_block!.parent_region!
    end

    ### Block Management

    # The link before the first block.
    # Can be used as an insertion point for prepending blocks.
    # Works even if the region is empty.
    sig { returns(BlockLink) }
    def front
      @sentinel
    end

    # The link after the last block.
    # Can be used as an insertion point for appending blocks.
    # Works even if the region is empty.
    sig { returns(BlockLink) }
    def back
      @sentinel.prev_link!
    end

    sig { returns(T.nilable(Block)) }
    def first_block
      @sentinel.next_block
    end

    sig { returns(Block) }
    def first_block!
      T.must(first_block)
    end

    sig { returns(T.nilable(Block)) }
    def last_block
      @sentinel.prev_block
    end

    sig { returns(Block) }
    def last_block!
      T.must(last_block)
    end

    sig { returns(T::Boolean) }
    def empty?
      @sentinel.next_link == @sentinel
    end

    sig { returns(T::Boolean) }
    def one_block?
      !empty? && @sentinel.next_link!.next_link! == @sentinel
    end

    sig { returns(BlocksInRegion) }
    def blocks
      BlocksInRegion.new(self)
    end

    ## Insert a block at the beginning of this region. Returns the inserted block.
    sig { params(block: Block).returns(Block) }
    def prepend_block!(block)
      block.insert_into_region!(front)
      block
    end

    ## Insert a block into this region. Returns the inserted block.
    sig { params(block: Block).returns(Block) }
    def append_block!(block)
      block.insert_into_region!(back)
    end

    ## Remove a block from this region.
    sig { params(block: Block).returns(Region) }
    def remove_block!(block)
      raise "block is not a child of this region" if self != block.parent_region
      block.remove_from_region!
      self
    end

    ### Region Arguments

    ## Arguments of this region. Derived from the arguments of the first block.
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

    sig { returns(String) }
    def inspect
      "<region:#{object_id}>"
    end
  end
end
