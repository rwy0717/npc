# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class AddI32 < Operation
      extend T::Sig

      sig { void }
      def initialize()
        super()

        @lhs = T.let(Operand.new(self, 0), Operand)
        @rhs = T.let(Operand.new(self, 0), Operand)
        @result = T.let(Result.new(self, 0), Result)
      end
    end
  end
end
