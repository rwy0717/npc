# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class BoolConst < Operation
      extend T::Sig

      sig { params(value: T::Boolean).void }
      def initialize(value)
        super(
          attributes: {
            value: value,
          },
          results: [Bool]
        )
      end

      sig { override.returns(String) }
      def operator_name
        "bool_const"
      end
    end
  end
end
