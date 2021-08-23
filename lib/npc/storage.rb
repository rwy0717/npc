# typed: strict
# frozen_string_literal: true

module NPC
  module Storage
    extend T::Sig
    extend T::Helpers
    abstract!
  end

  module InMemory
    extend T::Generic
    include Storage
  end
end
