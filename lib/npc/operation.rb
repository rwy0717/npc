# typed: strict
# frozen_string_literal: true

require("npc/base")
require("npc/located")
require("npc/operand")
require("npc/result")

module NPC
  ## The base class for all operations in NPC.
  module Operation
    extend T::Sig
    extend T::Helpers

    include Located

    abstract!

    sig { abstract.returns(T::Array[Operand]) }
    def operands; end

    sig { abstract.returns(T::Array[Result]) }
    def results; end
  end
end
