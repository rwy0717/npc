# typed: strict
# frozen_string_literal: true

module NPC
  # The root/dummy node of a block's op list.
  class BlockSentinel < InBlock
    include T::Sig

    sig { void }
    def initialize
      super(self, self)
    end

    sig { returns(T::Boolean) }
    def empty?
      next_link == self
    end
  end
end
