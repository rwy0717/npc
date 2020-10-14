# typed: true
# frozen_string_literal: true
# frozen_string_literals: true

module NPC
  module BF
    extend T::Sig

    sig { params(builder: IBuilder).returns(ILang) }
    def lang(builder)
      b = builder.lang_builder('bf')
      b.op('inc_ptr') {}  # >.   ++ptr;
      b.op('dec_ptr') {}  # <.   --ptr;
      b.op('inc_val') {}  # +.   ++*ptr;
      b.op('dec_val') {}  # -    --*ptr;
      b.op('loop') {}     # [    while (*ptr) {
      b.op('done') {}     # ]    }
      b.op('print') {}    # .  	putchar(*ptr);
      b.op('read') {}     # ,    *ptr=getchar();
      b.build
    end
    module_function :lang
  end
end
