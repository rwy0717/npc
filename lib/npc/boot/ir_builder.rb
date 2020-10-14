# typed: false
# frozen_string_literal: true

module NPC
  module Boot
    ## Class which creates IRGen bindings for a given bootstrap language.
    ## This file is untyped, because of it's heavy use of define_method.
    class IRBuilder
      extend T::Sig

      sig { params(lang: Lang).returns(Class) }
      def self.generate(lang)
        c = Class.new(IRBuilder)
        inject_gen_methods(c, lang)
        c.define_method(:initialize) do
          super(lang)
        end
        c
      end

      sig { params(lang: Lang).void }
      def initialize(lang)
        @lang = lang
        @ir = T.let([], T::Array[Node])
      end

      sig { void }
      def pp
        ir.each(&:pp)
      end

      sig { params(c: Class, lang: Lang).returns(Class) }
      def self.inject_gen_methods(c, lang)
        lang.ops.each do |op|
          inject_gen_method(c, op)
        end
        c
      end

      sig { params(c: Class, op: Op).returns(Class) }
      def self.inject_gen_method(c, op)
        c.define_method(name_sym(op.name)) do |args = {}|
          node = Node.new(op, args)
          ir.append(node)
          node
        end
        c
      end

      sig { params(name: T.any(Symbol, String)).returns(Symbol) }
      def self.name_sym(name)
        name.to_sym
      end

      sig { returns(Lang) }
      attr_reader :lang

      sig { returns(T::Array[Node]) }
      attr_reader :ir
    end
  end
end
