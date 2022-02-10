# typed: strict
# frozen_string_literal: true

module NPC
  module VerificationError
    extend T::Sig
    extend T::Helpers

    interface!

    sig { abstract.returns(String) }
    def message; end
  end

  # Generic verification error class.
  class VerificationFailure < T::Struct
    extend T::Sig
    include VerificationError

    const :caller, T.nilable(T::Array[Thread::Backtrace::Location])
    const :message, String
  end

  class VerificationErrorList < T::Struct
    extend T::Sig
    include VerificationError

    const :errors, T::Array[VerificationError]

    sig { override.returns(String) }
    def message
      msg = ""
      errors.each do |error|
        msg << "\n" << error.message
      end
      msg
    end
  end

  module OperationVerifier
    extend T::Sig
    extend T::Helpers

    sig { abstract.params(operation: Operation).returns(T::Array[VerificationError]) }
    def verify(operation); end
  end

  class Verifier
    extend T::Sig

    sig { params(operation: Operation).returns(T::Array[VerificationError]) }
    def call(operation)
      []
    end
  end

  Verify = T.let(Verifier.new, Verifier)
end
