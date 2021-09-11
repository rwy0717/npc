# typed: strict
# frozen_string_literal: true

module NPC
  # Objects that require destruction.
  module Destroyable
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { overridable.void }
    def destroy!
    end
  end
end
