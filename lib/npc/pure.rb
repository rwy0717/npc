# typed: strict
# frozen_string_literal: true

require("npc/trait")

module NPC
  module Pure
    extend T::Sig
    extend T::Helpers
    include Trait
    abstract!

    class << self
      extend T::Sig

      # Cast an operation into the pure interface
      sig { params(operation: Operation).returns(T.nilable(Pure)) }
      def cast(operation)
        operation if operation.is_a?(Pure)
      end

      # Is this operation pure, does it have no side-effects?
      sig { params(operation: Operation).returns(T::Boolean) }
      def pure?(operation)
        Pure.cast(operation)&.pure? || false
      end
    end

    sig { returns(T::Boolean) }
    def pure?
      true
    end
  end
end
