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
        class << self
          extend T::Sig

          sig { returns(Module) }
          def build
            op = new(regions: [RegionKind::Decl])
            op.region(0).append_block!(Block.new)
            op
          end
        end

        extend T::Sig

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
        class << self
          extend T::Sig

          sig { params(params: T::Array[Type], result: T::Array[Type]).returns(Function) }
          def build(params, result)
            op = new(
              regions: [RegionKind::Exec],
              attributes: { result: result },
            )
            op.region(0).append_block!(Block.new(params))
            op
          end
        end

        extend T::Sig

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
        class << self
          extend T::Sig

          sig { params(rets: T::Array[Value]).returns(Return) }
          def build(rets = [])
            new(operands: rets)
          end
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
        class << self
          extend T::Sig

          sig { params(type: Type, value: T.untyped).returns(Constant) }
          def build(type, value)
            new(attributes: { type: type, value: value }, results: [type])
          end
        end
      end

      #
      # Arithmetic
      #

      class Add < Operation
        class << self
          extend T::Sig

          sig { params(lhs: Value, rhs: Value).returns(Add) }
          def build(lhs, rhs)
            super(
              operands: [lhs, rhs],
              results: [lhs.type],
            )
          end
        end

        include BinaryTrait
      end

      class Sub < Operation
        class << self
          extend T::Sig

          sig { params(lhs: T.nilable(Value), rhs: T.nilable(Value)).returns(Sub) }
          def build(lhs, rhs)
            new(
              operands: [lhs, rhs],
              results:  [lhs&.type],
            )
          end
        end

        include BinaryTrait
      end

      #
      # Memory Operations
      #

      # Load from a memory.
      class I32Load < Operation
        class << self
          extend T::Sig

          sig { params(base: Value, offset: Integer).returns(I32Load) }
          def build(base, offset = 0)
            new(
              operands: [base],
              attributes: { offset: offset },
            )
          end
        end

        extend T::Sig

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

      # Store to a memory.
      class Store < Operation
        class << self
          extend T::Sig

          sig { params(value: Value, base: Value, offset: Integer).returns(Store) }
          def build(value, base, offset: 0)
            super(
              operands: [value, base],
              attributes: {
                type: value.type,
                offset: offset,
                # align: align,
              },
            )
          end
        end

        extend T::Sig

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

      #
      # Local Operations
      #

      # A local variable in the current function.
      class Local
        extend T::Sig

        sig { params(type: Type).void }
        def initialize(type)
          @type = T.let(type, Type)
        end

        sig { returns(Type) }
        attr_accessor :type
      end

      # Get a local variable.
      class Get < Operation
        class << self
          extend T::Sig

          sig { params(local: Local).returns(Get) }
          def build(local)
            new(
              attributes: {
                local: local,
              },
              results: [local.type],
            )
          end
        end

        extend T::Sig

        sig { returns(String) }
        def operation_name
          "get"
        end

        sig { returns(Local) }
        def local
          T.cast(attribute(:local), Local)
        end

        sig { returns(Type) }
        def type
          local.type
        end

        sig { returns(Result) }
        def value
          result(0)
        end
      end

      # Set a local variable.
      class Set < Operation
        class << self
          extend T::Sig

          sig { params(local: Local, value: Value).returns(Set) }
          def build(local, value)
            super(
              attributes: {},
              operands:   [value],
            )
          end
        end

        extend T::Sig

        sig { returns(Local) }
        def local
          T.cast(attribute(:local), Local)
        end

        sig { returns(Type) }
        def type
          local.type
        end

        sig { returns(Operand) }
        def value_operand
          operand(0)
        end

        sig { returns(T.nilable(Value)) }
        def value
          value_operand.get
        end

        sig { returns(Value) }
        def value!
          value_operand.get!
        end
      end

      #
      # Lower-level, structure control flow operations.
      #

      # Create a label that can later be branched to via Br.
      class BrLoop < Operation
        class << self
          extend T::Sig

          sig { params(blocks: T.nilable(T::Array[Block])).returns(BrLoop) }
          def build(blocks = nil)
            op = new(
              regions: [RegionKind::Exec],
            )

            if blocks
              blocks.each { |block| op.body.append_block!(block) }
            else
              op.body.append_block!(Block.new)
            end

            op
          end
        end

        extend T::Sig

        sig { returns(Region) }
        def body
          region(0)
        end
      end

      #
      # "Structure Control Flow" Operations
      #

      # Create a label that can later be branched out of, via Br.
      class BrBlock < Operation
        class << self
          extend T::Sig

          # By default, creates a body block.
          sig { params(blocks: T.nilable(T::Array[Block])).returns(BrBlock) }
          def build(blocks = nil)
            op = new(
              regions: [RegionKind::Exec],
            )
            if blocks.nil?
              op.body.append_block!(Block.new)
            else
              blocks.each do |block|
                op.body.append_block!(block)
              end
            end

            op
          end
        end

        extend T::Sig

        sig { returns(Region) }
        def body
          region(0)
        end
      end

      # Branch into the beginning of a loop, or out to the end of a block.
      class Br < Operation
        class << self
          extend T::Sig

          sig { params(depth: Integer).returns(Br) }
          def build(depth)
            new(
              attributes: {
                depth: depth,
              }
            )
          end
        end

        extend T::Sig

        sig { returns(Integer) }
        def depth
          T.cast(attribute(:depth), Integer)
        end

        sig { params(value: Integer).returns(Integer) }
        def depth=(value)
          T.cast(set_attribute!(:depth, value), Integer)
        end
      end

      # Structured control flow in WASM.
      class If < Operation
        class << self
          extend T::Sig

          sig { params(test: T.nilable(Value)).returns(If) }
          def build(test)
            new(
              operands: [test],
              regions: [RegionKind::Exec, RegionKind::Exec]
            )
          end
        end

        sig { returns(Operand) }
        def test_operand
          operand(0)
        end

        sig { returns(T.nilable(Value)) }
        def test
          test_operand.get
        end

        sig { params(value: T.nilable(Value)).void }
        def test=(value)
          test_operand.reset!(value)
        end

        sig { returns(Region) }
        def then_region
          region(0)
        end

        sig { returns(Region) }
        def else_region
          region(0)
        end
      end

      # A terminator that marks the end of a loop or block.
      class End < Operation
        class << self
          extend T::Sig

          sig { returns(End) }
          def build
            new
          end
        end
      end

      # Unstructured control flow.
      class Goto < Operation
        class << self
          extend T::Sig

          sig { params(target: T.nilable(Block)).returns(Goto) }
          def build(target = nil)
            new(
              block_operands: [target],
            )
          end
        end

        extend T::Sig
        include Terminator

        sig { returns(BlockOperand) }
        def target_block_operand
          block_operand(0)
        end

        sig { returns(T.nilable(Block)) }
        def target
          target_block_operand.get
        end

        sig { returns(Block) }
        def target!
          target_block_operand.get!
        end

        sig { params(block: T.nilable(Block)).void }
        def target=(block)
          target_block_operand.reset!(block)
        end
      end

      # Unstructured control flow.
      class GotoIf < Operation
        class << self
          extend T::Sig

          sig do
            params(
              test: T.nilable(Value),
              then_block: T.nilable(Block),
              else_block: T.nilable(Block),
            ).returns(GotoIf)
          end
          def build(test, then_block, else_block)
            new(
              operands: [test],
              block_operands: [then_block, else_block],
            )
          end
        end

        extend T::Sig
        include Terminator

        sig { returns(Operand) }
        def test_operand
          operand(0)
        end

        sig { returns(T.nilable(Value)) }
        def test
          test_operand.get
        end

        sig { returns(Value) }
        def test!
          test_operand.get!
        end

        sig { params(value: Value).void }
        def test=(value)
          test_operand.reset!(value)
        end

        sig { returns(T.nilable(Block)) }
        def then_target
          block_operand(0).get
        end

        sig { returns(Block) }
        def then_target!
          block_operand(0).get!
        end

        sig { params(block: T.nilable(Block)).void }
        def then_target=(block)
          block_operand(0).reset!(block)
        end

        sig { returns(BlockOperand) }
        def then_target_block_operand
          block_operand(0)
        end

        sig { returns(BlockOperand) }
        def else_target_block_operand
          block_operand(1)
        end

        sig { returns(T.nilable(Block)) }
        def else_target
          block_operand(1).get
        end

        sig { returns(Block) }
        def else_target!
          block_operand(1).get!
        end

        sig { params(block: T.nilable(Block)).void }
        def else_target=(block)
          block_operand(1).reset!(block)
        end
      end
    end
  end
end
