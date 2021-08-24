# typed: strict
# frozen_string_literal: true

require "npc/linked"

module NPC
  class LinkedList
    extend T::Sig
    extend T::Generic

    abstract!

    Elem = type_member

    sig { void }
    def initialize
      @sentinel = T.let(LinkedSentinel.new, LinkedSentinel)
    end
  end
end
