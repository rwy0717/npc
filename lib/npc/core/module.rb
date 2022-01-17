# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    # Generic Top-level container for IR.
    class Module < Operation
      extend T::Sig

      sig do
        params(
          name: Symbol,
          loc: T.nilable(Location),
        ).void
      end
      def initialize(name, loc: nil)
        super(loc: loc)
        new_result

        @body_region = T.let(Region.new(operation: self), Region)
        @body_region.append_block!(Block.new)
      end

      ## Accessing the body of this module.

      sig { returns(Region) }
      attr_reader :body_region

      # The block that represents this module's body.
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
