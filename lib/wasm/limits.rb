# typed: true
# frozen_string_literal: true

module WASM
  class Limits < T::Struct
    prop :min, Integer
    prop :max, T.nilable(Integer)
  end
end
