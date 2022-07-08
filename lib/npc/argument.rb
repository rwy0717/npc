# typed: strict
# frozen_string_literal: true

require("npc/value")
require("npc/located")
require("npc/operation")

module NPC
  # An argument to a block.
  class Argument < Value
    extend T::Sig

    sig do
      params(
        parent_block: T.nilable(Block),
        type:         T.nilable(Type),
        first_use:    T.nilable(Operand),
      ).void
    end
    def initialize(parent_block = nil, type = nil, first_use = nil)
      super(type, first_use)
      @parent_block = T.let(parent_block, T.nilable(Block))
    end

    sig { returns(T.nilable(Block)) }
    attr_accessor :parent_block

    sig { returns(Block) }
    def parent_block!
      T.must(@parent_block)
    end

    # This argument's index in the owning block's argument array.
    # If this argument is not owned by a block, it's index is nil.
    sig { returns(T.nilable(Integer)) }
    def index
      @parent_block&.arguments&.find_index(self)
    end

    sig { returns(Integer) }
    def index!
      T.must(index)
    end

    # Since this argument is not the result of an operation, the definining operation is always nil.
    sig { override.returns(T.nilable(Operation)) }
    def defining_operation
      nil
    end

    # Since this argument is defined by it's owning block, its defining block is the owning block.
    sig { override.returns(T.nilable(Block)) }
    def defining_block
      @parent_block
    end

    sig { override.returns(T.nilable(Region)) }
    def defining_region
      @parent_block&.parent_region
    end
  end
end
