# typed: strict
# frozen_string_literal: true

require("npc/use")

module NPC
  # An input to an operation, and a reference to a value.
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
      super(value)
      @operation = T.let(operation, Operation)
      @index = T.let(index, Integer)
    end

    # The operation that this operand belongs to.
    sig { returns(Operation) }
    attr_reader :operation

    # This operand's index in the operation's operand array.
    sig { returns(Integer) }
    attr_reader :index

    sig { returns(String) }
    def to_s
      "(operand #{value})"
    end

    # Copy this operand into another operation.
    sig { params(operation: Operation).returns(Operand) }
    def copy_into(operation)
      operation.new_operand(@value)
    end
  end
end
