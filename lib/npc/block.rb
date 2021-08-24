# typed: strict
# frozen_string_literal: true

module NPC
  # A basic block.
  class Block < LinkedList
    include Base

    Elem = type_member(fixed: Operation)

    sig { params(arguments: T::Array[Argument]).void }
    def initialize(arguments: [])
      super
      @arguments = T.let(arguments, T::Array[Argument])
    end

    sig { returns(T::Array[Argument]) }
    attr_accessor :arguments

    # Append a new argument to this block. Returns the new argument.
    sig { params(location: Location).returns(Argument) }
    def new_argument(location)
      a = Argument.new(location, self, arguments.length)
      arguments << a
      a
    end
  end
end
