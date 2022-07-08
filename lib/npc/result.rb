# typed: false
# frozen_string_literal: true

require("npc/value")

module NPC
  # A result of an operation.
  class Result < Value
    extend T::Sig

    sig do
      params(
        parent_operation: T.nilable(Operation),
        type:             T.nilable(Type),
        first_use:        T.nilable(Operand),
      ).void
    end
    def initialize(parent_operation, type, first_use = nil)
      super(type, first_use)
      @parent_operation = T.let(parent_operation, T.nilable(Operation))
    end

    sig { returns(T.nilable(Operation)) }
    attr_accessor :parent_operation

    sig { returns(Operation) }
    def parent_operation!
      T.must(@parent_operation)
    end

    sig { returns(T.nilable(Integer)) }
    def index
      @parent_operation&.results&.find_index(self)
    end

    sig { returns(Integer) }
    def index!
      T.must(index)
    end

    sig { override.returns(T.nilable(Operation)) }
    def defining_operation
      @parent_operation
    end

    sig { override.returns(T.nilable(Block)) }
    def defining_block
      @parent_operation&.parent_block
    end

    sig { override.returns(T.nilable(Region)) }
    def defining_region
      @parent_operation&.parent_region
    end
  end
end
