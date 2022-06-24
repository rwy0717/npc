# typed: strict
# frozen_string_literal: true

module NPC
  module WASM
    class Local < T::Struct
      prop :type, Symbol
      prop :size, Integer
    end
  end
end
