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
        owning_block: Block,
        index: Integer,
        type: Type,
        first_use: T.nilable(Operand),
      ).void
    end
    def initialize(owning_block, index, type, first_use = nil)
      super(type, first_use)
      @owning_block = T.let(owning_block, Block)
      @index = T.let(index, Integer)
      @type = T.let(type, Type)
    end

    sig { returns(Integer) }
    attr_reader :index

    #
    # This is an argument to the owning block.
    #
    sig { returns(Block) }
    attr_reader :owning_block

    #
    # Since this argument is not the result of an operation, the definining operation is always nil.
    #
    sig { override.returns(T.nilable(Operation)) }
    def defining_operation
      nil
    end

    #
    # Since this argument is defined by it's owning block, its defining block is the owning block.
    #
    sig { override.returns(T.nilable(Block)) }
    def defining_block
      @owning_block
    end

    sig { override.returns(T.nilable(Region)) }
    def defining_region
      @owning_block.parent_region
    end
  end
end
