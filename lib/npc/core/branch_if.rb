# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class BranchIf < Operation
      extend T::Sig
      include Terminator

      sig do
        params(
          predicate: T.nilable(Value),
          then_target: T.nilable(Block),
          else_target: T.nilable(Block),
          arguments: T::Array[T.nilable(Value)],
          loc: T.nilable(Location),
        ).void
      end
      def initialize(predicate, then_target, else_target, arguments = [], loc: nil)
        super(
          operands: [predicate, *arguments],
          block_operands: [then_target, else_target],
          loc: loc
        )
      end

      sig { override.returns(String) }
      def operator_name
        "branch_if"
      end
    end
  end
end
