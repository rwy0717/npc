# typed: true
# frozen_string_literal: true

module NPC
  module Meta
    extend T::Sig

    sig { params(b: NPC::IBuilder).returns(NPC::ILangBuilder) }
    def meta_lang_builder(b)
      b.lang_builder("meta").definition do
        op("lang") do
          attr("operations", "array_i32")
        end
        op("pass") do
          attr("name", "string")
        end
      end
    end
    module_function :meta_lang_builder

    sig { params(b: NPC::IBuilder).returns(NPC::ILang) }
    def meta_lang(b)
      meta_lang_builder(b).build
    end
    module_function :meta_lang

    sig { params(b: NPC::IBuilder).returns(IPass) }
    def id_pass(b)
      b.pass("id") {}
    end
    module_function :id_pass
  end
end
