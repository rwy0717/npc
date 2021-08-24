# typed: strict
# frozen_string_literal: true

require("npc/use")

module NPC
  # A reference to a value, used by an operation.
  class Operand < Use
    extend T::Sig

    sig do
      params(
        operation: Operation,
        index: Integer,
        value: T.nilable(Value),
      ).void
    end
    def initialize(operation, index, value = nil)
      @operation = T.let(operation, Operation)
      @index = T.let(index, Integer)
      super(value)
    end

    # The operation that this operand is a part of.
    sig { returns(Operation) }
    attr_reader :operation

    # The index of this operand in the operation.
    sig { returns(Integer) }
    attr_reader :index
  end
end
