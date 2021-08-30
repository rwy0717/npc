# typed: strict
# frozen_string_literal: true

# module NPC
#   class InsertPoint < BlockIterator
#     extend T::Sig

#     sig { params(iter: T.nilable(BlockIterator)).void }
#     def initialize(iter: nil)
#       @iter = T.let(iter, T.nilable(BlockIterator))
#     end

#     sig { returns(T::Boolean) }
#     def set?
#       @iter != nil
#     end

#     sig { returns(Block) }
#     def block
#       @iter.block
#     end
#   end
# end
