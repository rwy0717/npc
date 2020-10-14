# typed: true
# frozen_string_literal: true
# frozen_string_literals: true

module Std
  extend T::Sig
  sig { params(builder: NPC::IBuilder).returns(NPC::ILang) }
  def lang(builder)
    builder.lang("std") do
      op("i32_add") do
        parm("lhs", "i32")
        parm("rhs", "i32")
      end
      op("i32_const") do
        attr("val", "i32")
      end
    end
  end
  module_function :lang
end
