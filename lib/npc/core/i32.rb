# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class I32
      include Base
      include Type

      const :value, Integer

      sig do
        params(
          value: Integer
        ).void
      end
      def initialize(value)
        super(value: value)
      end
    end

    sig do
      params(
        value: Integer
      ).returns(I32)
    end
    def i32(value)
      I32.new(value)
    end
  end
end
