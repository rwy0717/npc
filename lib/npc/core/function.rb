# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class Function < Op
      extend T::Sig

      sig do
        params(
          location: Location,
          name: String,
          region: Region
        ).void
      end
      def initialize(location, name, region = Region.new)
        super(
          location: location,
          operands: [],
          results:  [],
        )
        @name   = T.let(name, String)
        @region = T.let(region, Region)
      end

      sig { override.returns(T::Array[Operand]) }
      def operands
        []
      end

      sig { override.returns(T::Array[Result]) }
      def results
        [Result.new(self, 0)]
      end
    end
  end
end
