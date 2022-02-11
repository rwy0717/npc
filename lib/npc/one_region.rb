# typed: strict
# frozen_string_literal: true

module NPC
  module OneRegion
    class << self
      extend T::Sig
      include OperationVerifier

      sig { override.params(operation: Operation).returns(T.nilable(Error)) }
      def verify(operation)
        if operation.regions.length == 1
          return ErrorMessage.new("operation has more than one region")
        end

        nil
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
