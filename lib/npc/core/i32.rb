# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class I32Type
      extend T::Sig
      extend T::Helpers
      include Type
    end

    I32 = T.let(I32Type.new, I32Type)
  end
end
