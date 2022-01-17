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
        block: Block,
        index: Integer,
        type: Type,
      ).void
    end
    def initialize(block, index, type)
      super()
      @block = T.let(block, Block)
      @index = T.let(index, Integer)
      @type  = T.let(type, Type)
    end

    # The block this is an argument to.
    sig { returns(Block) }
    attr_reader :block

    # The argument index.
    sig { returns(Integer) }
    attr_reader :index

    # The type of this argument.
    sig { returns(Type) }
    attr_reader :type
  end
end
