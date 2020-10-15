# typed: true
# frozen_string_literal: true

module NPC
  module Boot
    class Lang
      extend T::Sig
      include ILang
      include Sexpr

      sig { params(builder: LangBuilder).void }
      def initialize(builder)
        @name = builder.name

        @ops = T.let({}, T::Hash[String, Op])
        builder.ops.each do |op|
          @ops[op.name] = op
        end
      end

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String).returns(Op) }
      def op(name)
        @ops.fetch(name)
      end

      sig { returns(T::Enumerator[Op]) }
      def ops
        @ops.each_value
      end

      sig { override.returns(Array) }
      def sexpr_terms
        terms = [name]
        ops.each { |o| terms.append(o.to_str) }
        terms
      end
    end
  end
end
