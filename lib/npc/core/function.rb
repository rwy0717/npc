# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    # A function Definition
    class Function < Operation
      extend T::Sig
      include OneRegion

      sig do
        params(
          name: String,
          region: Region,
          # parameter_types: T::Array[Type],
          # result_types:
          loc: T.nilable(Location),
        ).void
      end
      def initialize(name, region = Region.new, loc: nil)
        super(
          regions: 1,
          attributes: {
            name: name,
          },
          loc: loc,
        )

        region(0).append_block!(Block.new)
      end

      sig { override.returns(String) }
      def operator_name
        "function"
      end

      sig { returns(String) }
      def name
        T.cast(attribute(:name), String)
      end

      sig { returns(Block) }
      def entry_block
        body_region.first_block!
      end

      # Add a new block to the end of the body region.
      sig { params(argument_types: T::Array[Type]).returns(Block) }
      def new_block!(argument_types = [])
        b = Block.new(argument_types)
        append_block!(b)
        b
      end

      sig { params(block: Block).returns(T.self_type) }
      def prepend_block!(block)
        body_region.prepend_block!(block)
        self
      end

      sig { params(block: Block).returns(T.self_type) }
      def append_block!(block)
        body_region.append_block!(block)
        self
      end
    end
  end
end
