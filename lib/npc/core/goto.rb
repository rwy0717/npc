# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class Goto < Operation
      extend T::Sig
    #   include Terminator

      sig do
        params(
          target: T.nilable(Block),
          arguments: T::Array[T.nilable(Value)],
          loc: T.nilable(Location),
        ).void
      end
      def initialize(target, arguments, loc: nil)
        super(
          block_operands: [target],
          operands: arguments,
          loc: loc
        )
      end

      sig { override.returns(String) }
      def operator_name
        "goto"
      end
    end
  end
end
