# typed: strict
# frozen_string_literal: true

require "npc/base"

module NPC
  # A node in an intrusive linked list.
  class Linked
    extend T::Sig

    sig { void }
    def initialize
      @link_next = T.let(nil, T.untyped)
      @link_prev = T.let(nil, T.untyped)
    end

    sig { returns(T.nilable(T.self_type)) }
    def link_prev
      to_self_type(@link_prev)
    end

    sig { returns(T.nilable(T.self_type)) }
    def link_next
      to_self_type(@link_next)
    end

    sig { returns(T.self_type) }
    def link_prev!
      T.must(link_prev)
    end

    sig { returns(T.self_type) }
    def link_next!
      T.must(link_next)
    end

    sig { void }
    def drop
    end

    private

    # Convert X to this type, if it is one. Otherwise, return nil.
    sig { params(x: T.untyped).returns(T.nilable(T.self_type)) }
    def to_self_type(x)
      x if !x.nil? && x.is_a?(T.self_type)
    end
  end
end
