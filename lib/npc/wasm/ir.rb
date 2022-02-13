# typed: strict
# frozen_string_literal: true

# https://webassembly.github.io/spec/core/syntax/instructions.html

module NPC
  module WASM
    module IR
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

      class IntType < Type
        sig { params(width: Integer).void }
        def initialize(width)
          super()
          @width = T.let(width, Integer)
        end

        sig { returns(Integer) }
        attr_reader :width
      end

      class IntTypeTable
        extend T::Sig

        sig { void }
        def initialize
          @table = T.let({}, T::Hash[Integer, IntType])
        end

        sig { returns(T::Hash[Integer, IntType]) }
        attr_reader :table

        sig { params(width: Integer).returns(IntType) }
        def [](width)
          table[width] ||= IntType.new(width)
        end
      end

      Int = T.let(IntTypeTable.new, IntTypeTable)
      I8  = T.let(Int[8],  IntType)
      I16 = T.let(Int[16], IntType)
      I32 = T.let(Int[32], IntType)
      I64 = T.let(Int[64], IntType)

      #
      # Top-level Declarations
      #

      class Module < Operation
        extend T::Sig
        # include DeclarativeOperation

        sig { void }
        def initialize
          super(regions: [RegionKind::Decl])
        end

        sig { returns(Region) }
        def body_region
          region(0)
        end

        sig { returns(Block) }
        def body_block
          body_region.first_block!
        end
      end

      class Function < Operation
        extend T::Sig

        sig { params(args: T::Array[Type], ret: Type).void }
        def initialize(args, ret)
          super(
            regions: [RegionKind::Exec],
            attributes: { ret: ret },
          )
          region(0).append_block!(Block.new(args))
        end

        sig { returns(Region) }
        def body_region
          region(0)
        end

        sig { returns(Block) }
        def entry_block
          region(0).first_block!
        end
      end

      class Memory < Operation
        extend T::Sig
      end

      class Global < Operation
        extend T::Sig
      end

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
end
