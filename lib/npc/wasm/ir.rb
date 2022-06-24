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
        VALID_WIDTHS = T.let(::Set[8, 16, 32, 64, 128].freeze, T::Set[Integer])

        sig { params(width: Integer).void }
        def initialize(width)
          super()
          @width = T.let(width, Integer)
          raise "invalid width: #{width}" unless VALID_WIDTHS.member?(width)
        end

        sig { returns(Integer) }
        attr_reader :width

        sig { override.returns(String) }
        def name
          "i#{width}"
        end

        sig { override.returns(String) }
        def to_s
          name
        end

        sig { override.returns(String) }
        def inspect
          name
        end
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

      class FuncType
        extend T::Sig

        sig { params(args: T::Array[Type], rets: T::Array[Type]).void }
        def initialize(args = [], rets = [])
          @args = T.let(args.dup.freeze, T::Array[Type])
          @rets = T.let(rets.dup.freeze, T::Array[Type])
          freeze
        end

        sig { returns(T::Array[Type]) }
        attr_reader :args

        sig { returns(T::Array[Type]) }
        attr_reader :rets

        sig { returns(String) }
        def name
          "(#{args.join(", ")}) -> (#{rets.join(", ")})"
        end
      end

      class FuncTypeTable
        extend T::Sig
        extend T::Helpers

        Key = T.type_alias { [T::Array[Type], T::Array[Type]] }

        sig { void }
        def initialize
          @table = T.let({}, T::Hash[Key, FuncType])
        end

        sig { params(args: T::Array[Type], rets: T::Array[Type]).returns(FuncType) }
        def [](args, rets)
          @table[[args, rets]] ||= FuncType.new(args, rets)
        end
      end

      Func = T.let(FuncTypeTable.new, FuncTypeTable)

      #
      # Top-level Declarations
      #

      class Module < Operation
        extend T::Sig
        # include DeclarativeOperation

        sig { void }
        def initialize
          super(regions: [RegionKind::Decl])
          region(0).append_block!(Block.new)
        end

        sig { returns(Region) }
        def body_region
          region(0)
        end

        sig { returns(Block) }
        def body_block
          body_region.first_block!
        end

        sig { override.returns(String) }
        def operator_name
          "module"
        end
      end

      class Function < Operation
        extend T::Sig

        sig { params(params: T::Array[Type], result: T::Array[Type]).void }
        def initialize(params, result)
          super(
            regions: [RegionKind::Exec],
            attributes: { result: result },
          )
          region(0).append_block!(Block.new(params))
        end

        sig { returns(Region) }
        def body_region
          region(0)
        end

        sig { returns(Block) }
        def entry_block
          region(0).first_block!
        end

        sig { returns(FuncType) }
        def type
          Func[param_types, result_types]
        end

        sig { returns(T::Array[Type]) }
        def param_types
          entry_block.arguments.map(&:type!)
        end

        sig { returns(T::Array[Type]) }
        def result_types
          T.cast(attribute(:result), T::Array[Type])
        end
      end

      class Memory < Operation
        extend T::Sig
      end

      class Global < Operation
        extend T::Sig
      end

      #
      # Control Flow
      #

      class Return < Operation
        extend T::Sig

        sig { params(rets: T::Array[Value]).void }
        def initialize(rets)
          super(operands: rets)
        end
      end

      #
      # Global and Locals
      #

      class GetLocal < Operation; end
      class SetLocal < Operation; end

      class GetGlobal < Operation; end
      class SetGlobal < Operation; end

      #
      # Constants
      #

      class Constant < Operation
        extend T::Sig

        sig { params(type: Type, value: T.untyped).void }
        def initialize(type, value)
          super(attributes: { type: type, value: value }, results: [type])
        end
      end

      #
      # Arithmetic
      #

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

      #
      # Memory Operations
      #

      class I32Load < Operation
        class << self
          extend T::Sig
        end

        extend T::Sig

        sig { params(base: Value, offset: Integer).void }
        def initialize(base, offset = 0)
          super(
            operands: [base],
            attributes: { offset: offset },
          )
        end

        sig { returns(Operand) }
        def base_operand
          operand(0)
        end

        sig { returns(T.nilable(Value)) }
        def base
          base_operand.get
        end

        sig { returns(Integer) }
        def offset
          T.cast(attribute(:offset), Integer)
        end
      end

      #
      # Memory Operations
      #

      class Store < Operation
        extend T::Sig

        sig { params(value: Value, base: Value, offset: Integer).void }
        def initialize(value, base, offset: 0)
          super(
            operands: [value, base],
            attributes: {
              type: value.type,
              offset: offset,
              # align: align,
            },
          )
        end

        sig { returns(Operand) }
        def base_operand
          operand(0)
        end

        sig { returns(T.nilable(Value)) }
        def base
          base_operand.get
        end

        sig { returns(Value) }
        def base!
          base_operand.get!
        end

        sig { returns(Integer) }
        def offset
          T.cast(attribute(:offset), Integer)
        end
      end
    end

    #
    # Local Operations
    #

    # class Local
    #   extend T::Sig

    #   sig { params(type: Type).void }
    #   def initialize(type)
    #     @type = T.let(type, Type)
    #   end

    #   sig { returns(Type) }
    #   attr_accessor :type
    # end

    #   class Get < Operation
    #     extend T::Sig

    #     sig { params(local: Local).void }
    #     def initialize(local)
    #       super(
    #         attributes: {
    #           local: local,
    #         },
    #         results: [local.type]
    #       )
    #     end

    #     sig { returns(String) }
    #     def operation_name
    #       "get"
    #     end

    #     sig { returns(Local) }
    #     def local
    #       T.cast(attribute(:local), Local)
    #     end

    #     sig { returns(Type) }
    #     def type
    #       local.type
    #     end

    #     sig { returns(Result) }
    #     def value
    #       result(0)
    #     end
    #   end

    #   class Set < Operation
    #     extend T::Sig

    #     sig { params(local: Local, value: Value).void }
    #     def initialize(local, value)
    #       super(
    #         attributes: {},
    #         operands:   [value]
    #       )
    #     end

    #     sig { returns(Local) }
    #     def local
    #       T.cast(attribute(:local), Local)
    #     end

    #     sig { returns(Type) }
    #     def type
    #       local.type
    #     end

    #     sig { returns(Value) }
    #     def value
    #       operand(0)
    #     end
    #   end
    # end
  end
end
