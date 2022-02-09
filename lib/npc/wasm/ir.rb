# typed: strict
# frozen_string_literal: true

# https://webassembly.github.io/spec/core/syntax/instructions.html

module NPC
  module WASM
    #
    # Helper Traits
    #

    module BinaryTrait
      extend T::Sig
      include OperationTrait

      LHS_INDEX = 0
      RHS_INDEX = 1

      sig { returns(Operand) }
      def lhs_operand
        operand(LHS_INDEX)
      end

      sig { returns(T.nilable(Value)) }
      def lhs
        lhs_operand.get
      end

      sig { returns(Value) }
      def lhs!
        lhs_operand.get!
      end

      sig { params(value: T.nilable(Value)).void }
      def lhs=(value)
        lhs_operand.reset!(value)
      end

      sig { returns(Operand) }
      def rhs_operand
        operand(RHS_INDEX)
      end

      sig { returns(T.nilable(Value)) }
      def rhs
        rhs_operand.get
      end

      sig { returns(Value) }
      def rhs!
        rhs_operand.get!
      end

      sig { params(value: T.nilable(Value)).void }
      def rhs=(value)
        rhs_operand.reset!(value)
      end

      sig { returns(Result) }
      def value
        result
      end
    end

    #
    # Types
    #

    # https://llvm.org/docs/LangRef.html#poison-values
    class PoisonType < Type
      extend T::Sig

      sig { override.returns(String) }
      def name
        "poison"
      end
    end

    Poison = T.let(PoisonType.new, PoisonType)

    #
    # Core IR
    #

    class PoisonConst < Operation
      extend T::Sig

      sig { void }
      def initialize
        super(results: [Poison])
      end

      sig { override.returns(String) }
      def operator_name
        "poison.const"
      end
    end

    class Constant < Operation
      extend T::Sig

      sig { params(value: T.untyped).void }
      def initialize(value)
        super(attributes: { value: value })
      end
    end

    class Add < Operation
      extend T::Sig
      include BinaryTrait

      sig { params(lhs: Value, rhs: Value).void }
      def initialize(lhs, rhs)
        super(
          operands: [lhs, rhs],
          results: [lhs.type],
        )
      end
    end

    class Sub < Operation
      extend T::Sig
      include BinaryTrait

      sig { params(lhs: Value, rhs: Value).void }
      def initialize(lhs, rhs)
        super(
          operands: [lhs, rhs],
          results: [lhs.type],
        )
      end
    end
  end
end
