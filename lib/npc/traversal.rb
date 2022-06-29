# typed: strict
# frozen_string_literal: true

# @file External iterators for walking IR trees.

module NPC
  # Iterate blocks in post-order.
  class PostOrderIter
    class Frame < T::Struct
      const :block, Block
      const :iterator, ArrayIterator[Block]
    end

    extend T::Sig
    extend T::Generic
    include Iterator

    Elem = type_member { { fixed: Block } }

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
      !@visited.add?(block).nil?
    end

    sig { params(block: Block).returns(Frame) }
    def new_frame(block)
      Frame.new(
        block: block,
        iterator: ArrayIterator.new(block.successors),
      )
    end
  end

  # A classic enumerable that iterates over the blocks in a region in post order.
  class PostOrder
    extend T::Sig
    extend T::Generic
    include Enumerable

    Elem = type_member { { fixed: Block } }

    # The entry block.
    sig { params(block: Block).void }
    def initialize(block)
      @block = T.let(block, Block)
    end

    sig { override.params(proc: T.proc.params(arg0: Block).returns(BasicObject)).returns(T.self_type) }
    def each(&proc)
      PostOrderIter.new(@block).each! do |block|
        proc.call(block)
      end
      self
    end
  end

  # Iterate blocks in pre-order.
  # For the
  class PreOrderIterator
    extend T::Sig
    extend T::Generic
    include Iterator

    Elem = type_member { { fixed: Block } }

    sig { params(block: Block).void }
    def initialize(block)
      @known = T.let(Set[block], T::Set[Block])
      @queue = T.let([block],    T::Array[Block])
      enqueue_successors(block)
    end

    #
    # Iterator Interface
    #

    sig { override.returns(Elem) }
    def get
      T.must(@queue.first)
    end

    sig { override.void }
    def advance!
      raise "cannot advance past end of sequence" if @queue.empty?

      @queue.shift
      current = @queue.first
      enqueue_successors(current) if current
    end

    sig { override.returns(T::Boolean) }
    def done?
      @queue.empty?
    end

    sig { params(block: Block).void }
    def enqueue_successors(block)
      terminator = block.terminator
      return unless terminator

      terminator.block_operands.each do |block_operand|
        successor_block = block_operand.get
        if successor_block && @known.add?(successor_block)
          @queue << successor_block
        end
      end
    end
  end

  class PreOrder
    extend T::Sig
    extend T::Generic
    include Enumerable

    Elem = type_member { { fixed: Block } }

    sig { params(block: Block).void }
    def initialize(block)
      @block = T.let(block, Block)
    end

    sig { override.params(proc: T.proc.params(arg0: Block).returns(BasicObject)).returns(T.self_type) }
    def each(&proc)
      PreOrderIterator.new(@block).each! do |block|
        proc.call(block)
      end
      self
    end
  end
end
