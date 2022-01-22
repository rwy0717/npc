# typed: strict
# frozen_string_literal: true

require("npc/operation_verifier")

module NPC
  module OneRegion
    class << self
      extend T::Sig
      include OperationVerifier

      sig { override.params(operation: Operation).returns(T::Boolean) }
      def verify(operation)
        return false unless operation.is_a?(OneRegion)
        operation.regions.length == 1
      end
    end

    extend T::Sig
    extend T::Helpers
    include OperationTrait

    sig { returns(Region) }
    def body_region
      region(0)
    end
  end
end
