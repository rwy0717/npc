# typed: strict
# frozen_string_literal: true

module NPC
  # A reference to a value, used by an operation.
  class Operand < Use
    include Base

    sig do
      params(
        operation: Operation,
        index: Integer,
        value: T.nilable(Value)
      ).void
    end
    def initialize(operation, index, value = nil)
      super(value)
      @operation = T.let(operation, Operation)
      @index = T.let(index, Integer)
    end

    # The operation that this operand is a part of.
    sig { returns(Operation) }
    attr_reader :operation

    # Set the value that this operand points to.
    sig do
      params(
        x: T.nilable(Value)
      ).returns(T.nilable(Value))
    end
    def value=(x)
      drop
      @value = x
    end

    # Clear the value this operand points to.
    sig { override.void }
    def clear
      self.value = nil
    end
  end
end
