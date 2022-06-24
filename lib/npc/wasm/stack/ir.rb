# typed: false
# frozen_string_literal: true

module NPC
  module WASM
    module Stack
      module IR
        class BasicOperation < NPC::Operation
          extend T::Sig
        end

        class I32Const < BasicOperation
        end

        class I32Add < BasicOperation
        end
      end
    end
  end
end
