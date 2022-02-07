# typed: strict
# frozen_string_literal: true

# @file External iterators for walking IR trees.

module NPC
  class PostOrderBlockSuccessorsIterator
    class Frame < T::Struct
      const :block, Block
      const :iterator, ArrayIterator[Block]
    end

    extend T::Sig
    extend T::Generic
    include Iterator

    Elem = type_member(fixed: Block)

    sig { params(block: Block).void }
    def initialize(block)
      @visited  = T.let(Set[], T::Set[Block])
      @stack    = T.let([],    T::Array[Frame])
      enter!(block)
      enter!(iterator.next!) while frame.iterator.more?
    end

    #
    # Iterator Interface
    #

    sig { override.returns(Elem) }
    def get
      frame.block
    end

    sig { override.void }
    def advance!
      raise "cannot advance past end of sequence" if stack.empty?
      leave!
      return if stack.empty?
      enter!(iterator.next!) while frame.iterator.more?
    end

    sig { override.returns(T::Boolean) }
    def done?
      stack.empty?
    end

    private

    sig { returns(T::Array[Frame]) }
    attr_reader :stack

    sig { returns(Frame) }
    def frame
      T.must(@stack.last)
    end

    sig { returns(ArrayIterator[Block]) }
    def iterator
      frame.iterator
    end

    sig { returns(Block) }
    def block
      frame.block
    end

    # Try to enter a block. No-op if the block is already visited.
    sig { params(block: Block).void }
    def enter!(block)
      @stack << new_frame(block) if mark!(block)
    end

    # Leave the current block.
    sig { returns(Block) }
    def leave!
      frame = @stack.pop
      raise "popped past end of stack" if frame.nil?
      raise "block not fully traversed" if frame.iterator.more?
      frame.block
    end

    # Have we seen this block before?
    sig { params(block: Block).returns(T::Boolean) }
    def visited?(block)
      @visited.member?(block)
    end

    # Mark the block as visited.
    # True if block hasn't been visited yet, indicating a successful mark.
    # False if the block has already been visited.
    sig { params(block: Block).returns(T::Boolean) }
    def mark!(block)
      @visited.add?(block) != nil
    end

    sig { params(block: Block).returns(Frame) }
    def new_frame(block)
      Frame.new(
        block: block,
        iterator: ArrayIterator.new(block.successors),
      )
    end
  end
end
