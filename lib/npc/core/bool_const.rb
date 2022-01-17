# typed: strict
# frozen_string_literal: true

require("npc/core/bool")

module NPC
  module Core
    class BoolConst < Operation
      extend T::Sig
  
      sig { params(value: T::Boolean).void }
      def initialize(value)
        super
        @value = T.let(value, T::Boolean)
        new_result
      end

      # Get the compile-time boolean value of this constant operation.
      sig { returns(T::Boolean) }
      def value
        T.cast(attribute(:constant), T::Boolean)
      end

      # sig { override.params(result: Result).returns(T.untyped) }
      # def constant_result(result)
      # end
    end
  end
end
