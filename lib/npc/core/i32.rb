# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class I32Type < Type
      extend T::Sig
      extend T::Helpers

      sig { override.returns(String) }
      def name
        "i32"
      end
    end

    I32 = T.let(I32Type.new, I32Type)
  end
end
