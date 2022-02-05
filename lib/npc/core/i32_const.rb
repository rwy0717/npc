# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class I32Const < Operation
      extend T::Sig
      include Const

      sig { params(value: Integer, loc: T.nilable(Location)).void }
      def initialize(value, loc: nil)
        super(
          attributes: {
            value: value,
          },
          results: [I32],
          loc: loc,
        )
      end

      sig { override.returns(String) }
      def operator_name
        "i32.const"
      end
    end
  end
end
