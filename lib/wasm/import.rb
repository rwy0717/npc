# typed: true
# frozen_string_literal: true

module WASM
  class Import < T::Struct
    prop :name, String
    prop :type, Symbol
    prop :index, Integer
  end
end
