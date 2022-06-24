# typed: strict
# frozen_string_literal: true

module NPC
  module WASM
    class Limits < T::Struct
      prop :min, Integer
      prop :max, T.nilable(Integer)
    end
  end
end
