# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class Return < Operation
      extend T::Sig
      include Terminator

      sig do
        params(
          value: T.nilable(Value),
          loc: T.nilable(Location),
        ).void
      end
      def initialize(value, loc: nil)
        super(
          operands: [value],
          loc: loc
        )
      end

      sig { override.returns(String) }
      def operator_name
        "return"
      end
    end
  end
end
