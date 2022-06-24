# typed: strict
# frozen_string_literal: true

module NPC
  module WASM
    class Export < T::Struct
      prop :name, String
      prop :type, Symbol
      prop :index, Integer
    end
  end
end
