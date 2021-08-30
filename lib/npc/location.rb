# typed: strict
# frozen_string_literal: true

require "npc/base"

module NPC
  module Location
    extend T::Sig
    extend T::Helpers
    interface!
  end

  class UnknownLocation < T::Struct
    extend T::Sig
    include Location
  end

  class KnownLocation < T::Struct
    extend T::Sig
    include Location

    const :row, Integer
    const :col, Integer
    const :file, String
  end
end
