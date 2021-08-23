# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class I32Const < Op
      extend T::Sig
      include Operation
      include Const

      sig { params(location: Location, value: Integer).void }
      def initialize(location, value)
        super(
          location,
          operands: [],
          results: [Result.new(self, 0)]
        )
        @value = T.let(value, Integer)
      end

      sig { returns(Integer) }
      attr_reader :value
    end
  end
end
