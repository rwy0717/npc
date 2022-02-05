# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class I32Add < Operation
      extend T::Sig

      sig do
        params(
          lhs: T.nilable(Value),
          rhs: T.nilable(Value),
          loc: T.nilable(Location)
        ).void
      end
      def initialize(lhs = nil, rhs = nil, loc: nil)
        super(
          operands: [lhs, rhs],
          results: [I32],
          loc: loc,
        )
      end

      sig { override.returns(String) }
      def operator_name
        "i32.add"
      end

      sig { returns(Operand) }
      def lhs
        operands.fetch(0)
      end

      sig { returns(Operand) }
      def rhs
        operands.fetch(1)
      end

      # sig { returns(Result) }
      # def result
      #   results.fetch(0)
      # end
    end
  end
end
