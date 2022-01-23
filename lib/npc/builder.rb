# typed: false
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

    sig { returns(OperationLink) }
    def insertion_point
      @point
    end

    sig { params(point: OperationLink).void }
    def set_insertion_point!(point)
      @point = point
    end

    # Insert the op at the current insertion point and move the insertion point forwards.
    # Returns the inserted op.
    sig do
      type_parameters(:T)
        .params(operation: T.type_parameter(:T))
        .returns(T.type_parameter(:T))
    end
    def insert!(operation)
      operation.insert_into_block!(@point)
      @point = operation
      operation
    end

    # Try to fold away the operation before insertion.
    sig { params(operation: Operation).returns(T::Array[Value]) }
    def insert_or_fold!(operation)
      results = fold(operation)
      if results
        # TODO: Destroy the operation?
        results
      else
        insert!(operation)
        operation.results
      end
    end

    sig { params(operation: Operation).returns(T.nilable(T::Array[Value])) }
    def fold(operation)
      return nil if operation.is_a?(Constant)
      return nil unless operation.is_a?(Foldable)

      constant_operands = operation.operands.map do |operand|
        Constant.constant_value(operand.value)
      end

      results = operation.fold(constant_operands)
      return nil unless results

      values = results.map do |result|
        case result
        when Value
          result
        when AbstractConstant
          constant = result.materialize
          insert!(constant)
          T.must(constant.results[0])
        end
      end

      values
    end
  end
end
