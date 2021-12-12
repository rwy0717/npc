# typed: strict
# frozen_string_literal: true

module NPC
  # When an operation can be folded away, this is the value or constant used as it's substitution.
  FoldValue = T.type_alias { T.any(Value, AbstractConstant) }

  # An extremely limited interface for folding away operations as they are created.
  module Foldable
    extend T::Sig
    extend T::Helpers

    abstract!

    # Try to fold this operation. If this operation can be folded away, return
    # the constants to be used instead. May not mutate the operation.
    sig { abstract.params(operands: T::Array[FoldValue]).returns(T.nilable(T::Array[FoldValue])) }
    def fold(operands); end
  end
end
