# typed: strict
# frozen_string_literal: true

require_relative("test")

class TestIterator < Minitest::Test
  # The following tests if we can implement the iter
  # interface with a fixed type.
  # !!! WARNING, HOLY FUCK SORBET
  # !!! when overriding `get`:
  # !!! the return type must be `Elem`
  # !!! not the underlying fixed type.
  class Iter123
    extend T::Sig
    extend T::Generic
    include NPC::Iterator
    Elem = type_member { { fixed: Integer } }

    sig { void }
    def initialize
      @i = T.let(1, Integer)
    end

    sig { override.returns(T::Boolean) }
    def done?
      @i > 3
    end

    sig { override.returns(Elem) }
    def get
      @i
    end

    sig { override.void }
    def advance!
      @i += 1
    end
  end

  extend T::Sig

  sig { void }
  def test_iter123
    assert_equal([1, 2, 3], Iter123.new.to_a!)
  end
end

class TestArrayIterator < Minitest::Test
  extend T::Sig

  sig { void }
  def test_to_a
    iter = T.let(
      NPC::ArrayIterator.new([1, 2, 3]),
      NPC::ArrayIterator[Integer],
    )

    assert_equal([1, 2, 3], iter.to_a!)
  end
end
