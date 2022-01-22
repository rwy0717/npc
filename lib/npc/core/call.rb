# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class Call < Operation
      extend T::Sig
      extend T::Helpers

      sig do
        params(
          callee: Symbol,
          arguments: T::Array[Value],
        ).void
      end
      def initialize(callee, arguments)
        super(
          operands: arguments,
          attributes: {
            callee: callee,
          },
        )

        @callee    = callee
        @arguments = arguments
      end

      # TODO: How do we represent the callee?
      # Need a symbol-ref or something... can we have typed references?
      sig { returns(T.untyped) }
      def callee
        attribute(:callee)
      end

      sig { returns(T::Array[Operand]) }
      def arguments
        operands
      end
    end
  end
end
