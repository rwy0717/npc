# typed: true
# frozen_string_literal: true

module NPC
  module Boot
    class LangBuilder
      extend T::Sig
      include ILangBuilder
      include Sexpr

      sig { override.params(name: String).void }
      def initialize(name)
        @name = name
      end

      sig { override.params(block: T.proc.bind(ILangBuilder).void).returns(ILangBuilder) }
      def definition(&block)
        instance_eval(&block)
        self
      end

      sig { override.params(name: String).returns(IOpBuilder) }
      def op_builder(name)
        OpBuilder.new(self, name)
      end

      sig { override.params(name: String, block: T.proc.bind(IOpBuilder).void).returns(ILangBuilder) }
      def op(name, &block)
        op_builder(name).definition(&block).build
        self
      end

      sig { params(name: String).returns(ILangBuilder) }
      def simple_op(name)
        op_builder(name).build
        self
      end

      sig { override.returns(ILang) }
      def build
        Lang.new(self)
      end

      sig { params(op: Op).returns(Op) }
      def attach_op(op)
        ops << op
        op
      end

      sig { override.returns(Array) }
      def sexpr_terms
        [name].concat(ops)
      end

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Array[Op]) }
      attr_reader :ops
    end
  end
end
