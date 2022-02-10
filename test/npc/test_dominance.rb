# typed: strict
# frozen_string_literal: true

require_relative("test")

class TestDominatorTree < MiniTest::Test
  extend T::Sig

  sig { void }
  def test_single_block
    m = NPC::Core::Module.new("example")
    b = m.region(0).first_block!

    tree = NPC::DominatorTree.new(m.region(0))
    n = tree.node(b)

    assert_equal(n, n.parent)
    assert_equal(b, n.block)
    assert_equal(0, n.index)
  end

  sig { void }
  def test_linear_cfg
    m = NPC::Core::Module.new("example")
    f = NPC::Core::Function.new("test")
    m.region(0).first_block!.append_operation!(f)
    r = f.region(0)

    b0 = r.first_block!
    b1 = r.append_block!(NPC::Block.new)

    b0.append_operation!(NPC::Core::Goto.new(b1))

    tree = NPC::DominatorTree.new(r)

    n0 = tree.node(b0)
    n1 = tree.node(b1)

    assert_equal(n0, n0.parent)
    assert_equal(b0, n0.block)
    assert_equal(1,  n0.index)

    assert_equal(n0, n1.parent)
    assert_equal(b1, n1.block)
    assert_equal(0,  n1.index)
  end

  sig { void }
  def test_diamond_cfg
    m = NPC::Core::Module.new("example")
    f = NPC::Core::Function.new("test")
    m.region(0).first_block!.append_operation!(f)
    r = f.region(0)

    b0 = r.first_block!
    b1 = r.append_block!(NPC::Block.new)
    b2 = r.append_block!(NPC::Block.new)
    b3 = r.append_block!(NPC::Block.new)

    t = NPC::Core::BoolConst.new(true)

    b0.append_operation!(t)
    b0.append_operation!(NPC::Core::BranchIf.new(t.result(0), b1, b2))
    b1.append_operation!(NPC::Core::Goto.new(b3))
    b2.append_operation!(NPC::Core::Goto.new(b3))

    tree = NPC::DominatorTree.new(r)

    n0 = tree.node(b0)
    n1 = tree.node(b1)
    n2 = tree.node(b2)
    n3 = tree.node(b3)

    assert_equal(n0, n0.parent)
    assert_equal(b0, n0.block)
    assert_equal(3,  n0.index)

    assert_equal(n0, n1.parent)
    assert_equal(b1, n1.block)
    assert_equal(1,  n1.index)

    assert_equal(n0, n2.parent)
    assert_equal(b2, n2.block)
    assert_equal(2,  n2.index)

    assert_equal(n0, n3.parent)
    assert_equal(b3, n3.block)
    assert_equal(0,  n3.index)
  end
end

class TestDominance < MiniTest::Test
  extend T::Sig
end
