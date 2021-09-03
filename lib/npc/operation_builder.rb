# typed: strict
# frozen_string_literal: true

require("sorbet-runtime")

require("npc/block")
require("npc/insertion_point")
require("npc/operation")

module NPC
  class OperationBuilder
    extend T::Sig

    class << self
      extend T::Sig

      ## Construct a new builder with the insertion point set to the end of the block.
      sig { params(block: Block).returns(OperationBuilder) }
      def block_back(block)
        OperationBuilder.new(at: block.back)
      end
    end

    sig { params(at: OperationLink).void }
    def initialize(at:)
      @point = T.let(at, OperationLink)
      @block = T.let(T.must(at.block), Block)
    end

    ## Insertion point tracking and management.

    # Block of the current insertion point.
    # If the op
    sig { returns(T.nilable(Block)) }
    attr_reader :block

    # Get a copy of the current insertion point.
    sig { returns(OperationLink) }
    def insertion_point
      @point
    end

    # Set the insertion point of the builder.
    sig { params(point: OperationLink).returns(OperationLink) }
    def insertion_point=(point)
      @block = T.must(point.block)
      @point = point
    end

    # Save the insertion point, run the block, and then reset the insertion point.
    sig { params(proc: T.proc.void).returns(OperationBuilder) }
    def with_position(&proc)
      saved  = @point
      proc.call
      @point = saved
      self
    end

    ## Block Insertion

    # Create a new block and put it into the region.
    # sig { params(region: Region, arg_types: T::Array[Type]).returns(Block) }
    # def create_block(region, iter, arg_types: [])
    #   Block.new(region, iter, arg_types)
    # end

    ## Operation Creation

    # Create a new op and insert it. Returns the new op.
    # sig do
    #   params(
    #     type: T.class_of(Operation),
    #     args: T::Array[T.untyped],
    #   ).returns(Operation)
    # end
    # def create(type, *args)
    #   insert(type.new(*args))
    # end
  end
end
