# typed: strict
# frozen_string_literal: true

module NPC
  # Example IR, used in tests.
  module ExIR
    class NumberType < Type
      include Singleton
    end

    NumTy = T.let(NumberType.instance, NumberType)

    class Module < Operation
      extend T::Sig

      sig { void }
      def initialize
        super(
          regions: [RegionKind::Decl]
        )

        region(0).append_block!(Block.new)
      end
    end

    class Function < Operation
      extend T::Sig

      sig { params(parameters: T::Array[Type], results: T::Array[Type]).void }
      def initialize(parameters = [], results = [])
        super(
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

      sig { params(value: Integer).void }
      def initialize(value)
        super(
          attributes: {
            value: value,
          }
        )
      end
    end

    class Add < Operation
      extend T::Sig

      sig { params(lhs: Value, rhs: Value).void }
      def initialize(lhs, rhs)
        super(
          operands: [lhs, rhs],
          results: [NPC::ExIR::NumTy],
        )
      end
    end

    class Goto < Operation
      extend T::Sig
      include Terminator

      sig { params(target: Block, arguments: T::Array[Value]).void }
      def initialize(target, arguments = [])
        super(
          operands: arguments,
          block_operands: [target],
        )
      end
    end

    class GotoN < Operation
      extend T::Sig
      include Terminator

      sig { params(targets: T::Array[Block], arguments: T::Array[Value]).void }
      def initialize(targets, arguments = [])
        super(
          operands: arguments,
          block_operands: targets,
        )
      end
    end

    class Return < Operation
      extend T::Sig
      include Terminator

      sig { params(arguments: T::Array[Value]).void }
      def initialize(arguments = [])
        super(
          operands: arguments
        )
      end
    end
  end
end
