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
          loc: T.nilable(Location),
        ).void
      end
      def initialize(name, region = Region.new, loc: nil)
        super(
          location: loc,
          regions: 1,
          attributes: {
            name: name,
          }
        )
      end

      sig { returns(String) }
      def name
        T.cast(attribute(:name), String)
      end
    end
  end
end
