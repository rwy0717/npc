# typed: strict
# frozen_string_literal: true

module NPC
  module WASM
    # Enforce stack-correctness, by moving temporary values
    # into intermediate locals.
    # class FunctionToStack
    #   include OperationPass

    #   element = t.type_member { { fixed: IR::Function } }

    #   def run(context, operation)
    #     # backwards pass to decide when a result has to be pushed into a local.
    #   end
    # end

    # class WASMToStack
    #   include Pass

    #   # def
    #   # sig { params(run) }
    # end
  end
end
