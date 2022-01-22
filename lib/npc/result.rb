# typed: false
# frozen_string_literal: true

require("npc/value")

module NPC
  # A result of an operation.
  class Result < Value
    extend T::Sig

    sig do
      params(
        owning_operation: Operation,
        index: Integer,
        type: Type,
        first_use: T.nilable(Operand),
      ).void
    end
    def initialize(owning_operation, index, type, first_use = nil)
      super(type, first_use)
      @owning_operation = T.let(owning_operation, Operation)
      @index = T.let(index, Integer)
    end

    sig { returns(Integer) }
    attr_reader :index

    sig { returns(Operation) }
    attr_reader :owning_operation

    sig { override.returns(T.nilable(Operation)) }
    def defining_operation
      @owning_operation
    end

    sig { override.returns(T.nilable(Block)) }
    def defining_block
      @owning_operation&.parent_block
    end

    sig { override.returns(T.nilable(Region)) }
    def defining_region
      @owning_operation&.parent_region
    end
  end
end
