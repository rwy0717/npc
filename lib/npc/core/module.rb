# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class Module < Operation
      extend T::Sig

      sig do
        params(
          location: Location,
          name: Symbol,
        ).void
      end
      def initialize(location, name)
        super(
          operation: self,
          location: location,
          operands: [],
          results: [
            Result.new(self, 0),
          ],
        )

        @body_region = T.let(Region.new(operation: self), Region)
        @body_region.append_block!(Block.new)
      end

      sig { returns(Region) }
      attr_reader :body_region

      sig { returns(Block) }
      def body_block
        T.must(body_region.first_block)
      end
    end
  end
end
