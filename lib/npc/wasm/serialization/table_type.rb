# typed: strict
# frozen_string_literal: true

module NPC
  module WASM
    class TableType < T::Struct
      prop :limits, Limits
      prop :elem_type, Symbol, default: :anyfunc
    end
  end
end
