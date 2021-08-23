# typed: true
# frozen_string_literal: true

module NPC
  class Region
    include Base

    class << self
      include Base

      sig { params(block: T.nilable(Block)).returns(Region) }
      def with_block(block)
        block ||= Block.new(arguments: [])
        Region.new(
          entry_block: block,
          blocks: [block],
        )
      end
    end

    sig do
      params(
        entry_block: T.nilable(Block),
        blocks: T::Array[Block],
      ).void
    end
    def initialize(
      entry_block: nil,
      blocks: []
    )
      @entry_block = T.let(entry_block, T.nilable(Block))
      @blocks = T.let(blocks, T::Array[Block])
    end

    sig { returns(T.nilable(Block)) }
    attr_accessor :entry_block

    sig { returns(T::Array[Block]) }
    attr_accessor :blocks
  end
end
