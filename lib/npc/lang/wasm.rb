# typed: true
# frozen_string_literal: true

module NPC
  class WASM
    extend T::Sig

    sig { params(builder: NPC::IBuilder).returns(ILang) }
    def lang(builder)
      builder.lang("wasm") do
        op("i32.add") {}
        op("i32.const") { attr("val", "i32") }
      end
    end
    module_function :lang
  end
end
