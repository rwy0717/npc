# typed: strict
# frozen_string_literal: true

module NPC
  class VoidType < Type
    extend T::Sig
    extend T::Helpers
  end

  Void = T.let(VoidType.new, VoidType)
end
