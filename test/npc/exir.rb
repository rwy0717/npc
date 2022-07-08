# typed: strict
# frozen_string_literal: true

module NPC
  # Example IR, used in tests.
  module ExIR
    class NumberType < Type
      include Singleton
    end

    NumTy = T.let(NumberType.instance, NumberType)
    Num   = T.let(NumberType.instance, NumberType)

    class Module < Operation
      extend T::Sig

      sig { params(name: T.nilable(String)).returns(Module) }
      def self.build(name = nil)
        op = new(
          regions: [RegionKind::Decl],
          attributes: { name: name },
        )
        op.region(0).append_block!(Block.new)
        op
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
    end

    class Function < Operation
      extend T::Sig

      sig { params(parameters: T::Array[Type], results: T::Array[Type]).returns(Function) }
      def self.build(parameters = [], results = [])
        new(
          attributes: {
            parameters: parameters,
            results: results,
          },
          regions: [RegionKind::Exec]
        )

        region(0).append_block!(Block.new(parameters))
      end
    end

    class Const < Operation
      extend T::Sig

      sig { params(value: Integer).returns(Const) }
      def self.build(value)
        new(
          attributes: {
            value: value,
          }
        )
      end
    end

    class Add < Operation
      extend T::Sig

      sig { params(lhs: T.nilable(Value), rhs: T.nilable(Value)).returns(Add) }
      def self.build(lhs, rhs)
        new(
          operands: [lhs, rhs],
          results: [NPC::ExIR::NumTy],
        )
      end
    end

    class Goto < Operation
      extend T::Sig
      include Terminator

      sig { params(target: Block, arguments: T::Array[Value]).returns(Goto) }
      def self.build(target, arguments = [])
        new(
          operands: arguments,
          block_operands: [target],
        )
      end
    end

    class GotoN < Operation
      extend T::Sig
      include Terminator

      sig { params(targets: T::Array[Block], arguments: T::Array[Value]).returns(GotoN) }
      def self.build(targets, arguments = [])
        new(
          operands: arguments,
          block_operands: targets,
        )
      end
    end

    # Like GotoN but takes a test value
    class GotoIf < Operation
      extend T::Sig
      include Terminator

      sig do
        params(
          test:      T.nilable(Value),
          targets:   T::Array[T.nilable(Block)],
          arguments: T::Array[T.nilable(Value)],
        ).returns(GotoIf)
      end
      def self.build(test = nil, targets = [], arguments = [])
        new(
          operands: [test, *arguments],
          block_operands: targets,
        )
      end
    end

    class Return < Operation
      extend T::Sig
      include Terminator

      sig { params(arguments: T::Array[Value]).returns(Return) }
      def self.build(arguments = [])
        new(
          operands: arguments
        )
      end
    end
  end
end
