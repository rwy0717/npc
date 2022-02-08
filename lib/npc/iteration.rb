# typed: strict
# frozen_string_literal: true

# Basic external iterators.

module NPC
  # A stateful iterator that is driven externally.
  # Useful for when the iteration state needs to be paused
  # or incrementally updated.
  module Iterator
    extend T::Sig
    extend T::Helpers
    extend T::Generic
    Elem = type_member(:out)

    abstract!

    #
    # Base Interface--to be defined by users.
    #

    sig { abstract.returns(T::Boolean) }
    def done?; end

    sig { abstract.void }
    def advance!; end

    sig { abstract.returns(Elem) }
    def get; end

    #
    # Additional Methods and Helpers
    #

    sig { overridable.returns(T::Boolean) }
    def more?
      !done?
    end

    sig { overridable.returns(Elem) }
    def next!
      x = get
      advance!
      x
    end

    # Consume the iterator and repeatedly call the block.
    sig { overridable.params(proc: T.proc.params(arg0: Elem).returns(T.untyped)).void }
    def each!(&proc)
      proc.call(next!) while more?
    end

    # Consume the iterator and convert it to an array.
    sig { returns(T::Array[Elem]) }
    def to_a!
      a = []
      a << next! while more?
      a
    end
  end

  class ArrayIterator
    extend T::Sig
    extend T::Generic
    include Iterator

    Elem = type_member

    sig { params(array: T::Array[Elem], index: Integer).void }
    def initialize(array, index = 0)
      @array = T.let(array, T::Array[Elem])
      @index = T.let(index, Integer)
    end

    sig { override.void }
    def advance!
      raise "advanced past end of array" if done?
      @index += 1
    end

    sig { override.returns(Elem) }
    def get
      raise "cannot fetch from iterator after end" if done?
      @array.fetch(@index)
    end

    sig { override.returns(T::Boolean) }
    def done?
      @index >= @array.length
    end
  end
end
