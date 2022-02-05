# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class BoolType < Type
      extend T::Sig
    end

    BOOL_TYPE = T.let(BoolType.new, BoolType)
  end
end
