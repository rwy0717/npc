# typed: strict
# frozen_string_literal: true

module NPC
  ## The base class for all operations in NPC.
  module Operation
    include Base
    include Located

    abstract!

    sig { abstract.returns(T::Array[Operand]) }
    def operands; end

    sig { abstract.returns(T::Array[Result]) }
    def results; end
  end
end
