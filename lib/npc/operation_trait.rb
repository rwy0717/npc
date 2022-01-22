# typed: strict
# frozen_string_literal: true

module NPC
  module OperationTrait
    extend T::Sig
    extend T::Helpers

    requires_ancestor { NPC::Operation }
  end
end
