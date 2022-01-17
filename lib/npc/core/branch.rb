# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class Branch < Operation
      extend T::Sig

      include Terminator
      include Pure

      sig do
        params(
          target: Block,
          operands: T::Array[Value],
          loc: T.nilable(Location),
        ).void
      end
      def initialize(target, operands, loc: nil)
        super(
          block_operands: [target],
          operands: operands,
          loc: loc
        )
      end

      sig { returns(BlockOperand) }
      def target
        block_operands.fetch(0)
      end

      sig { returns(T.nilable(Block)) }
      def target_block
        target.get
      end

      sig { returns(Block) }
      def target_block!
        target.get!
      end
    end
  end
end
