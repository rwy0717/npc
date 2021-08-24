# typed: strict
# frozen_string_literal: true

module NPC
  # Something that is tied back to a source-location.
  module Located
    extend T::Sig
    extend T::Helpers

    interface!

    # The original source-location of this object.
    sig { abstract.returns(Location) }
    def location; end
  end
end
