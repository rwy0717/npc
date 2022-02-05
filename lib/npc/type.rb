# typed: strict
# frozen_string_literal: true

module NPC
  class Type
    extend T::Sig

    sig { overridable.returns(String) }
    def name
      T.must(self.class.name)
    end
  end
end
