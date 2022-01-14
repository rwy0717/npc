# typed: strict
# frozen_string_literal: true
module NPC
  # No operands.
  module Nullary
    extend T::Sig
    extend T::Helpers

    sig { returns(T::Array[Operand]) }
    def operands
      []
    end
  end

  # One operand.
  module Unary
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.returns(Operand) }
    def operand; end

    sig { returns(T::Array[Operand]) }
    def operands
      [operand]
    end
  end

  # Two operands.
  module Binary
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.returns(Operand) }
    def operand_a; end

    sig { abstract.returns(Operand) }
    def operand_b; end

    sig { returns(T::Array[Operand]) }
    def operands
      [operand_a, operand_b]
    end
  end

  # Three operands.
  module Ternary
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.returns(Operand) }
    def operand_a; end

    sig { abstract.returns(Operand) }
    def operand_b; end

    sig { abstract.returns(Operand) }
    def operand_c; end

    sig { returns(T::Array[Operand]) }
    def operands
      [operand_a, operand_b, operand_c]
    end
  end

  class NullaryOperation < Operation
    extend T::Sig
    extend T::Helpers
    include Nullary
  end

  class UnaryOperation < Operation
    extend T::Sig
    extend T::Helpers
    include Unary

    sig { void }
    def initialize
      super
      @operand = T.let(new_operand, Operand)
    end

    sig { override.returns(Operand) }
    attr_reader :operand
  end
end
