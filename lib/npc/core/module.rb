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
          name: Symbol,
          loc: T.nilable(Location),
        ).void
      end
      def initialize(name, loc: nil)
        super(regions: 1, loc: loc)
      end
    end
  end
end
