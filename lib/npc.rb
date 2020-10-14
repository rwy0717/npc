# typed: true
# frozen_string_literal: true

require("sorbet-runtime")

module NPC
  module IBuilder
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.params(name: String).returns(ILangBuilder) }
    def lang_builder(name); end

    sig { abstract.params(name: String, block: T.proc.bind(ILangBuilder).void).returns(NPC::ILang) }
    def lang(name, &block); end

    sig { abstract.params(name: String).returns(NPC::IPassBuilder) }
    def pass_builder(name); end

    sig { abstract.params(name: String, block: T.proc.bind(IPassBuilder).void).returns(NPC::IPass) }
    def pass(name, &block); end
  end

  module ILangBuilder
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.params(name: String).void }
    def initialize(name); end

    sig { abstract.params(block: T.proc.bind(ILangBuilder).void).returns(ILangBuilder) }
    def definition(&block); end

    sig { abstract.params(name: String).returns(IOpBuilder) }
    def op_builder(name); end

    sig { abstract.params(name: String, block: T.proc.bind(IOpBuilder).void).returns(ILangBuilder) }
    def op(name, &block); end

    sig { abstract.returns(ILang) }
    def build(); end
  end

  module IOpBuilder
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.params(block: T.proc.bind(IOpBuilder).void).returns(IOpBuilder) }
    def definition(&block); end

    sig { abstract.params(name: String, type: String).returns(IOpBuilder) }
    def parm(name, type); end

    sig { abstract.params(name: String, type: String).returns(IOpBuilder) }
    def attr(name, type); end

    sig { abstract.returns(IOp) }
    def build; end
  end

  module IPassBuilder
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.params(block: T.proc.bind(IPassBuilder).void).returns(IPassBuilder) }
    def definition(&block); end

    sig { abstract.returns(IPass) }
    def build(); end
  end

  module IPass
    extend T::Sig
    extend T::Helpers
    interface!
  end

  module ILang
    extend T::Sig
    extend T::Helpers
    interface!
  end

  module IOp
    extend T::Sig
    extend T::Helpers
    interface!
  end
end

require 'npc/boot'
require 'npc/lang'
require 'npc/meta'
require 'npc/sexpr'
