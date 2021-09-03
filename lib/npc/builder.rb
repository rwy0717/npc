# typed: strict
# frozen_string_literal: true

require("npc/operation")
require("npc/block")
require("npc/region")

module NPC
  class Builder
    extend T::Sig

    class << self
      extend T::Sig

      # Insert before an operation.
      sig { params(point: OperationLink).returns(Builder) }
      def before(point)
        Builder.new(T.must(point.prev_link))
      end

      # Insert after a node.
      sig { params(point: OperationLink).returns(Builder) }
      def after(point)
        Builder.new(point)
      end

      # Insert at the front of a block.
      sig { params(block: Block).returns(Builder) }
      def at_front(block)
        Builder.new(block.front)
      end

      # Insert at the back of block.
      sig { params(block: Block).returns(Builder) }
      def at_back(block)
        Builder.new(block.back)
      end

      # Insert before the terminator of a block.
      sig { params(block: Block).returns(Builder) }
      def before_terminator(block)
        Builder.new(T.must(block.terminator))
      end
    end

    sig { params(point: OperationLink).void }
    def initialize(point)
      @point = point
    end

    # Insert the op at the current insertion point and move the insertion point forwards.
    # Returns the inserted op.
    sig { params(operation: Operation).returns(Operation) }
    def insert(operation)
      operation.insert_into_block!(@point)
      @point = operation
      operation
    end
  end
end
