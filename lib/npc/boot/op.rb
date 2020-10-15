# typed: false
# frozen_string_literal: true

module NPC
  module Boot
    ## An operation type in the bootstrap compiler.
    class Op
      extend T::Sig
      extend T::Helpers
      include IOp
      include Sexpr

      sig { params(builder: OpBuilder).void }
      def initialize(builder)
        @name = builder.name
        @attrs = builder.attrs.freeze
        @parms = builder.parms.freeze
      end

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Hash[String, String]) }
      attr_reader :attrs

      sig { returns(T::Hash[String, String]) }
      attr_reader :parms

      sig { override.returns(Array) }
      def sexpr_terms
        terms = [name]
        attrs.each { |k, v| terms.append("#{k}:#{v}") }
        parms.each { |k, v| terms.append("#{k}:#{v}") }
        terms
      end
    end
  end
end
