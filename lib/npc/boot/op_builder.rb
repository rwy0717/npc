# typed: true
# frozen_string_literal: true
# frozen_string_literals: true

module NPC
  module Boot
    class OpBuilder
      extend T::Sig
      include IOpBuilder
      include Sexpr

      sig { params(lang_builder: LangBuilder, name: String).void }
      def initialize(lang_builder, name)
        @lang_builder = lang_builder
        @name = name
        @parms = T.let({}, T::Hash[String, String])
        @attrs = T.let({}, T::Hash[String, String])
      end

      sig { override.params(block: T.proc.bind(IOpBuilder).void).returns(IOpBuilder) }
      def definition(&block)
        instance_eval(&block)
        self
      end

      sig { override.params(name: String, type: String).returns(IOpBuilder) }
      def parm(name, type)
        @parm[name] = type
        self
      end

      sig { override.params(name: String, type: String).returns(IOpBuilder) }
      def attr(name, type)
        @attrs[name] = type
        self
      end

      sig { override.returns(IOp) }
      def build
        @lang_builder.attach_op(Op.new(self))
      end

      sig { returns(LangBuilder) }
      attr_reader :lang_builder

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Hash[String, String]) }
      attr_reader :attrs

      sig { returns(T::Hash[String, String]) }
      attr_reader :parms

      sig { override.returns(Array) }
      def sexpr_terms
        terms = [name]
        attrs.each { |k, v| terms.append("#{k}: #{v}") }
        parms.each { |k, v| terms.append("#{k}: #{v}") }
        terms
      end
    end
  end
end
