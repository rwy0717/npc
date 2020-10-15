# typed: true
# frozen_string_literal: true

module NPC
  module Boot
    class PassBuilder
      extend T::Sig
      include IPassBuilder
      attr_reader :name

      sig { params(name: String).void }
      def initialize(name)
        @name = name
      end
    end

    class Pass
      extend T::Sig
      extend T::Helpers
      include IPass

      sig { params(builder: PassBuilder).void }
      def initialize(builder)
        builder
      end
    end

    class NodeType
      extend T::Sig
      attr_reader :name

      sig { params(name: T.any(String, Symbol)).void }
      def initialize(name)
        @name = T.let(name.to_s, String)
      end
    end
  end

  ## An IR element. Every node has an op and a set of concrete argument.
  class Node
    include Sexpr
    attr_accessor :op, :args

    def initialize(op, args = {})
      @op = op
      @args = args
    end

    def sexpr_terms
      terms = [op.name]
      args.each do |k, v|
        terms.append("#{k}:", v.to_s)
      end
      terms
    end
  end
end

require("npc/boot/builder")
require("npc/boot/ir_builder")
require("npc/boot/lang_builder")
require("npc/boot/lang")
require("npc/boot/op_builder")
require("npc/boot/op")
require("npc/boot/pass_builder")
