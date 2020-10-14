#!/usr/bin/env ruby
# typed: true
# frozen_string_literal: true

module NPC
  module Boot
    class Builder
      extend T::Sig
      include IBuilder

      sig { override.params(name: String).returns(ILangBuilder) }
      def lang_builder(name)
        LangBuilder.new(name)
      end

      sig { override.params(name: String, block: T.proc.bind(IBuilder).void).returns(ILang) }
      def lang(name, &block)
        lang_builder(name).definition(&block).build
      end

      sig { override.params(name: String).returns(IPassBuilder) }
      def pass_builder(name)
        PassBuilder.new(name)
      end

      sig { override.params(name: String, block: T.proc.bind(IPassBuilder).void).returns(IPass) }
      def pass(name, &block)
        pass_builder(name).definition(&block).build
      end
    end
  end
end
