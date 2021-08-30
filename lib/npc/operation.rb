# typed: strict
# frozen_string_literal: true

require("npc/base")
require("npc/located")
require("npc/operand")
require("npc/result")

module NPC
  module OperationLink
    extend T::Sig
    extend T::Helpers

    include Kernel

    abstract!

    sig { abstract.returns(T.nilable(Block)) }
    def block; end

    sig { abstract.returns(T.nilable(OperationLink)) }
    def prev_link; end

    sig { abstract.params(x: OperationLink).returns(T.nilable(OperationLink)) }
    def prev_link=(x); end

    sig { abstract.returns(T.nilable(OperationLink)) }
    def next_link; end

    sig { abstract.params(x: OperationLink).returns(T.nilable(OperationLink)) }
    def next_link=(x); end

    sig { returns(Block) }
    def block!
      T.must(block)
    end

    sig { returns(OperationLink) }
    def prev_link!
      T.must(prev_link)
    end

    sig { returns(OperationLink) }
    def next_link!
      T.must(next_link)
    end

    sig { returns(T.nilable(Operation)) }
    def prev_operation
      x = prev_link
      x if x.is_a?(Operation)
    end

    sig { returns(T.nilable(Operation)) }
    def next_operation
      x = next_link
      x if x.is_a?(Operation)
    end
  end

  ## Operations are stored in a circular doubly-linked list.
  ## This type sits at the root of the list, connecting the
  ## front of the list to the back.
  class OperationSentinel
    extend T::Sig
    include OperationLink

    sig { params(block: Block).void }
    def initialize(block)
      @block = T.let(block, Block)
      @prev_link = T.let(self, OperationLink)
      @next_link = T.let(self, OperationLink)
    end

    sig { override.returns(T.nilable(Block)) }
    attr_reader :block

    sig { override.returns(OperationLink) }
    attr_accessor :prev_link

    sig { override.returns(OperationLink) }
    attr_accessor :next_link
  end

  ## The base class for all operations in NPC.
  class Operation
    extend T::Sig
    extend T::Helpers

    include OperationLink

    sig do
      params(
        location: Location,
        operands: T::Array[Operand],
        results: T::Array[Result],
      ).void
    end
    def initialize(
      location:,
      operands:,
      results:
    )
      super()
      @location  = T.let(location, Location)
      @operands  = T.let(operands, T::Array[Operand])
      @results   = T.let(results,  T::Array[Result])
      @prev_link = T.let(nil, T.nilable(OperationLink))
      @next_link = T.let(nil, T.nilable(OperationLink))
    end

    ### Operation Links

    sig { override.returns(T.nilable(Block)) }
    attr_reader :block

    sig { params(block: T.nilable(Block)).returns(T.nilable(Block)) }
    attr_writer :block

    sig { override.returns(T.nilable(OperationLink)) }
    attr_accessor :prev_link

    sig { override.returns(T.nilable(OperationLink)) }
    attr_accessor :next_link

    sig { returns(T::Boolean) }
    def in_block?
      block != nil
    end

    sig { params(prev: OperationLink).void }
    def insert_into_block!(prev)
      raise "operation already in block" if
        @block || @prev_link || @next_link

      @block = T.must(prev.block)
      @prev_link = prev
      @next_link = prev.next_link!

      @prev_link.next_link = self
      @next_link.prev_link = self
    end

    sig { void }
    def remove_from_block!
      raise "operation not in block" unless
        @block && @prev_link && @next_link

      @prev_link.next_link = @next_link
      @next_link.prev_link = @prev_link

      @block = nil
      @prev_link = nil
      @next_link = nil
    end

    sig { params(point: OperationLink).void }
    def move!(point)
      remove_from_block! if in_block?
      insert_into_block!(point)
    end

    # The region that this op is in.
    sig { returns(T.nilable(Region)) }
    def region
      block&.region
    end

    ### Dropping and Destruction of Operation

    sig { void }
    def drop!
      remove_from_block! if in_block?
      drop_operands!
      drop_uses!
    end

    # Clear all operands in this operation.
    sig { void }
    def drop_operands!
      operands.each(&:drop!)
    end

    # Drop all references to this operation's results.
    sig { void }
    def drop_uses!
      results.each(&:drop_uses!)
    end

    # Replace the uses of this operation's results with the results of a different operation.
    sig { params(other: Operation).void }
    def replace_uses!(other)
      # TODO: Need to check that the types line up.
      # TODO: Need to check that these ops are in the same block.
      results.each do |result|
        result.replace_uses!(other.results[result.index])
      end
    end

    # Drop this operator from the block, and replace it with another.
    # The new operation will be inserted where
    sig { params(other: Operation).void }
    def replace!(other)
      raise "op must be in a block to be replaced" unless in_block?
      # TODO: Need to check that the types are compatible.
      cursor = prev_link!
      remove_from_block!
      other.insert_into_block!(cursor)
      replace_uses!(other)
    end

    ### Attributes

    sig { returns(Location) }
    attr_reader :location

    sig { returns(T::Array[Operand]) }
    attr_reader :operands

    sig { params(value: T.nilable(Value)).returns(Operand) }
    def new_operand(value = nil)
      operand = Operand.new(self, operands.length, value)
      operands << operand
      operand
    end

    sig { returns(T::Array[Result]) }
    attr_reader :results

    sig { returns(Result) }
    def new_result
      result = Result.new(self, results.length)
      results << result
      result
    end
  end
end
