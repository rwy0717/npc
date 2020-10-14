# typed: true
# frozen_string_literal: true

module NPC
  module Boot
    class PassBuilder
      extend T::Sig
      include IPassBuilder

      sig { params(name: String).void }
      def initialize(name)
        @name = name
      end

      sig { override.params(block: T.proc.bind(IPassBuilder).void).returns(IPassBuilder) }
      def definition(&block)
        instance_eval(&block)
        self
      end

      sig { override.returns(IPass) }
      def build
        Pass.new(self)
      end

      sig { returns(String) }
      attr_reader :name
    end
  end
end
