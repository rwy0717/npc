# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class IntegerConstant < Operation
      extend T::Sig
      extend T::Helpers

      sig { params(value: Integer).void }
      def initialize(value)
        @value = T.let(value, Integer)
      end

      sig { returns(Integer) }
      attr_accessor :value
    end
  end
end
