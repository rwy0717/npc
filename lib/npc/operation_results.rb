# typed: strict
# frozen_string_literal: true

module NPC
  # Mixin for operations with no results.
  module NoResult
    extend T::Sig
    extend T::Helpers

    sig { returns(T::Array[Result]) }
    def results
      []
    end
  end

  # Mixin for operations with one result.
  module OneResult
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.returns(Result) }
    def result; end

    sig { returns(T::Array[Result]) }
    def results
      [result]
    end
  end
end
