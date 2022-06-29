# typed: strict
# frozen_string_literal: true

module BF
  class SimplifyRepetitions
    extend T::Sig
    include Singleton
    include NPC::Pass

    sig do
      override.params(
        context: NPC::PassContext,
        target:  NPC::Operation,
      ).returns(NPC::PassResult)
    end
    def run(context, target)
      unless target.is_a?(IR::Program)
        return NPC::PassResult.failure
      end

      simplify_block!(target.body)
      NPC::PassResult.success
    end

    sig { params(block: NPC::Block).void }
    def simplify_block!(block)
      op = T.let(block.first_operation, T.nilable(NPC::Operation))
      while op
        case op
        when IR::Inc
          simplify_inc!(op)
        when IR::Dec
          simplify_dec!(op)
        when IR::MoveL
          simplify_move_l!(op)
        when IR::MoveR
          simplify_move_r!(op)
        when IR::Loop
          simplify_block!(op.body)
        end
        op = op.next_operation
      end
    end

    sig { params(op: IR::Inc).void }
    def simplify_inc!(op)
      loop do
        next_op = op.next_operation
        case next_op
        when IR::Inc
          op.amount = op.amount + next_op.amount
          next_op.drop!
        when IR::Dec
          op.amount = op.amount - next_op.amount
          next_op.drop!
        else
          break
        end
      end
    end

    sig { params(op: IR::Dec).void }
    def simplify_dec!(op)
      loop do
        next_op = op.next_operation
        case next_op
        when IR::Inc
          op.amount = op.amount - next_op.amount
          next_op.drop!
        when IR::Dec
          op.amount = op.amount + next_op.amount
          next_op.drop!
        else
          break
        end
      end
    end

    sig { params(op: IR::MoveL).void }
    def simplify_move_l!(op)
      loop do
        next_op = op.next_operation
        case next_op
        when IR::MoveL
          op.amount = op.amount + next_op.amount
          next_op.drop!
        when IR::MoveR
          op.amount = op.amount - next_op.amount
          next_op.drop!
        else
          break
        end
      end
    end

    sig { params(op: IR::MoveR).void }
    def simplify_move_r!(op)
      loop do
        next_op = op.next_operation
        case next_op
        when IR::MoveL
          op.amount = op.amount - next_op.amount
          next_op.drop!
        when IR::MoveR
          op.amount = op.amount + next_op.amount
          next_op.drop!
        else
          break
        end
      end
    end
  end
end
