# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class BoolType < Type
      extend T::Sig

      sig { override.returns(String) }
      def name
        "bool"
      end
    end

    Bool = T.let(BoolType.new, BoolType)
  end
end
