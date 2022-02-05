# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    # Logical 'and' operation for two boolean values.
    class And < Operation
      extend T::Sig

      sig { void }
      def initialize
        super
        new_operand
        new_operand
        new_result(BOOL_TYPE)
      end

      sig { returns(Operand) }
      def lhs
        operand(0)
      end

      sig { returns(Operand) }
      def rhs
        operand(1)
      end
    end
  end
end
