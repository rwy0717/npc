# typed: strict
# frozen_string_literal: true

module NPC
  # A basic block.
  class Block
    include Base

    sig { params(arguments: T::Array[Argument]).void }
    def initialize(arguments: [])
      @arguments = T.let(arguments, T::Array[Argument])
      @sentinel  = T.let(BlockSentinel.new, BlockSentinel)
    end

    sig { returns(T::Array[Argument]) }
    attr_accessor :arguments
  end
end
