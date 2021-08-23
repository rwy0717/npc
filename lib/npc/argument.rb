
# typed: strict
# frozen_string_literal: true

module NPC
  # An argument to a block.
  class Argument < Value
    include Base
    include Located

    sig do
      params(
        location: Location,
        block: Block,
        index: Integer,
      ).void
    end
    def initialize(location, block, index)
      @location = T.let(location, Location)
      @block = T.let(block, Block)
      @index = T.let(index, Integer)
    end

    # the source-loction of this block argument
    sig { override.returns(Location) }
    attr_reader :location

    # The block this is an argument to.
    sig { returns(Block) }
    attr_reader :block

    ## The argument index.
    sig { returns(Integer) }
    attr_reader :index

    sig { override.returns(T.nilable(Operation)) }
    def defining_operation
      nil
    end
  end
end
