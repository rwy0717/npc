# typed: strict
# frozen_string_literal: true

module NPC
  module GraphNode
    extend T::Sig
    extend T::Helpers
    extend T::Generic
    include Kernel
    abstract!

    # Return type must implement the {Iterator} interface.
    sig { abstract.returns(T.untyped) }
    def successors_iter; end
  end

  # Iterate nodes in post-order.
  class PostOrderGraphIter
    class Frame < T::Struct
      extend T::Generic

      Elem = type_member

      const :node, Elem
      const :iterator, T.untyped # rubocop:disable Sorbet/ForbidUntypedStructProps
    end

    extend T::Sig
    extend T::Helpers
    extend T::Generic
    include Iterator
    abstract!

    Elem = type_member { { upper: GraphNode } }

    sig { params(root: Elem).void }
    def initialize(root)
      @visited  = T.let(Set[], T::Set[Elem])
      @stack    = T.let([],    T::Array[Frame[Elem]])
      enter!(root)
      enter!(iterator.next!) while frame.iterator.more?
    end

    #
    # Iterator Interface
    #

    sig { override.returns(Elem) }
    def get
      frame.node
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

    sig { returns(T::Array[Frame[Elem]]) }
    attr_reader :stack

    sig { returns(Frame[Elem]) }
    def frame
      T.must(@stack.last)
    end

    sig { returns(T.untyped) }
    def iterator
      frame.iterator
    end

    sig { returns(Elem) }
    def node
      frame.node
    end

    # Try to enter a node. No-op if the node is already visited.
    sig { params(node: Elem).void }
    def enter!(node)
      if mark!(node)
        @stack << new_frame(node)
      end
    end

    # Leave the current node.
    sig { returns(Elem) }
    def leave!
      frame = @stack.pop
      raise "popped past end of stack" if frame.nil?
      raise "node not fully traversed" if frame.iterator.more?

      frame.node
    end

    # Have we seen this node before?
    sig { params(node: Elem).returns(T::Boolean) }
    def visited?(node)
      @visited.member?(node)
    end

    # Mark the node as visited.
    # True if node hasn't been visited yet, indicating a successful mark.
    # False if the node has already been visited.
    sig { params(node: Elem).returns(T::Boolean) }
    def mark!(node)
      !@visited.add?(node).nil?
    end

    sig { params(node: Elem).returns(Frame[Elem]) }
    def new_frame(node)
      Frame.new(
        node: node,
        iterator: node.successors_iter,
      )
    end
  end

  # Depth first traversal of a graph in preorder, using a stack.
  class PreOrderGraphIter
    extend T::Sig
    extend T::Helpers
    extend T::Generic
    include Iterator

    Elem = type_member { { upper: GraphNode } }

    sig { params(root: Elem).void }
    def initialize(root)
      @current = T.let(root, T.nilable(Elem))
      @stack   = T.let([], T::Array[T.untyped])
    end

    # @!group Iterator Interface

    sig { override.returns(Elem) }
    def get
      T.must(@current)
    end

    sig { override.void }
    def advance!
      if @current.nil?
        raise "cannot advance past end of sequence"
      end

      # If the current node has any children, get the
      # next child and put the iter on the stack.
      iter = @current.successors_iter
      if iter.more?
        @current = iter.next!
        if iter.more
          @stack.push(iter)
        end
        return
      end

      # The current node has no children, get the next
      # node from the stack.
      iter = @stack.last
      if iter
        @current = iter.next!
        @stack.pop if iter.done?
      else
        @current = nil
      end
    end

    sig { override.returns(T::Boolean) }
    def done?
      @stack.empty?
    end
  end
end
