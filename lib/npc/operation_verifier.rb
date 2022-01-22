# typed: strict
# frozen_string_literal: true

module NPC
  module OperationVerifier
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.params(operation: Operation).returns(T::Boolean) }
    def verify(operation); end
  end
end
