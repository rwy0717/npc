# typed: strict
# frozen_string_literal: true

module NPC
  # An IR entity that belongs to a block.
  class InBlock
    include Base

    sig do
      params(
        prev_link: T.nilable(InBlock),
        next_link: T.nilable(InBlock),
      ).void
    end
    def initialize(prev_link = nil, next_link = nil)
      @prev_link = T.let(prev_link, T.nilable(InBlock))
      @next_link = T.let(next_link, T.nilable(InBlock))
    end

    sig { returns(T.nilable(InBlock)) }
    attr_accessor :prev_link

    sig { returns(T.nilable(InBlock)) }
    attr_accessor :next_link

    sig { returns(T.nilable(Operation)) }
    def to_operation
      if is_a?(Operation)
        self
      end
    end

    sig { returns(T.nilable(Operation)) }
    def prev_operation
      p = prev_link
      p.to_operation if p
    end

    sig { returns(T.nilable(Operation)) }
    def next_operation
      n = next_link
      n.to_operation if n
    end
  end
end
