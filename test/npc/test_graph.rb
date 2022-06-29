# typed: true
# frozen_string_literal: true

require "npc/test"

class TestPostOrderGraphIter < Minitest::Test
  class MyNode < T::Struct
    extend T::Sig
    include NPC::GraphNode
    const :successors, T::Array[MyNode], factory: -> { [] }

    sig { override.returns(NPC::ArrayIterator[MyNode]) }
    def successors_iter
      NPC::ArrayIterator.new(successors)
    end
  end

  def test1
    n1 = MyNode.new
    n2 = MyNode.new
    n3 = MyNode.new

    n1.successors << n2
    n2.successors << n3

    assert_equal(
      [n1, n2, n3],
      NPC::PostOrderGraphIter.new(n1).to_a!,
    )
  end
end
