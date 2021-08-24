# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class Module < Op
      extend T::Sig

      sig do
        params(
          location: Location,
          _name: String,
          _region: Region,
        ).void
      end
      def initialize(location, _name, _region = Region.new)
        super(
          location: location,
          operands: [],
          results: [
            Result.new(self, 0),
          ],
        )
      end
    end
  end
end
