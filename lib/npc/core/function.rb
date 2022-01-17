# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    # A function Definition
    class Function < Operation
      extend T::Sig

      sig do
        params(
          name: String,
          region: Region,
          loc: T.nilable(Location),
        ).void
      end
      def initialize(name, region = Region.new, loc: nil)
        super(
          location: loc,
          operands: [],
          results:  [],
        )
        @name = T.let(name, String)
        @body_region = T.let(region, Region)
      end

      sig { override.returns(T::Array[Operand]) }
      def operands
        []
      end

      sig { override.returns(T::Array[Result]) }
      def results
        [Result.new(self, 0)]
      end

      ## Accessing the body of this function.

      sig { returns(Region) }
      attr_reader :body_region

      # The block that represents this function's body.
      sig { returns(Block) }
      def body
        T.must(body_region.first_block)
      end

      # The front of this module's body block.
      sig { returns(OperationLink) }
      def front
        body.front
      end

      # The back of this module's body block
      sig { returns(OperationLink) }
      def back
        body.back
      end
    end
  end
end
