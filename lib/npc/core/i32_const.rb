# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class I32Const < Operation
      extend T::Sig
      include Const

      sig { params(location: Location, value: Integer).void }
      def initialize(location, value)
        super(
          location: location,
          operands: [],
          results: [I32],
        )
        @value = T.let(value, Integer)
      end

      sig { returns(Integer) }
      attr_reader :value
    end
  end
end
