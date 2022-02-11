# typed: strict
# frozen_string_literal: true

module NPC
  module OperationVerifier
    extend T::Sig
    extend T::Helpers
    include Kernel

    abstract!

    sig { abstract.params(operation: Operation).returns(T.nilable(Error)) }
    def verify(operation); end

    # Helper method for signifying success
    # sig { returns(T::Array[VerificationError]) }
    # def success
    #   []
    # end

    # sig { params(message: String).returns(T.nilable(Error)) }
    # def failure(message)
    #   [VerificationFailure.new(
    #     caller:
    #       caller_locations,
    #     message: message
    #   )]
    # end
  end
end
