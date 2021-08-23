# typed: strict
# frozen_string_literal: true

module NPC
  # The result of an operation. An operation may have more than one result.
  class Result < Value
    include Base
    include Located

    sig do
      params(
        operation: Operation,
        index: Integer,
      ).void
    end
    def initialize(operation, index)
      super
      @operation = T.let(operation, Operation)
      @index = T.let(index, Integer)
    end

    sig { override.returns(Location) }
    def location
      operation.location
    end

    sig { returns(Operation) }
    attr_reader :operation

    sig { override.returns(T.nilable(Operation)) }
    def defining_operation
      operation
    end
  end
end
