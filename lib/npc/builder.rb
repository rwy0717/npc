# typed: strict
# frozen_string_literal: true

module NPC
  class Builder
    extend T::Sig

    class << self
      extend T::Sig

      # Insert before an operation.
      sig do
        params(
          _op: Operation,
        ).returns(Builder)
      end
      def before(_op)
        Builder.new
      end

      # Insert after a node.
      sig do
        params(
          _op: Operation,
        ).returns(Builder)
      end
      def after(_op)
        Builder.new
      end
    end
  end
end
