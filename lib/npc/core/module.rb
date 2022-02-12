# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    # Generic Top-level container for IR.
    class Module < Operation
      extend T::Sig
      include OneRegion

      sig do
        params(
          name: T.nilable(String),
          loc: T.nilable(Location),
        ).void
      end
      def initialize(name = nil, loc: nil)
        super(
          attributes: {
            name: name,
          },
          regions: [RegionKind::Decl],
          loc: loc,
        )
        body_region.append_block!(Block.new)
      end

      sig { override.returns(String) }
      def operator_name
        "module"
      end

      sig { returns(Block) }
      def body_block
        body_region.first_block!
      end
    end
  end
end
