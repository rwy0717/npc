# typed: strict
# frozen_string_literal: true

require_relative("test")

class TestPostOrderIter < MiniTest::Test
  extend T::Sig

  sig { void }
  def test_single_block
    m = NPC::ExIR::Module.build
    b = m.region(0).first_block!
    assert_equal([b], NPC::PostOrder.new(b).to_a)
  end

  sig { void }
  def test_linear_cfg
    m = NPC::ExIR::Module.build
    f = NPC::ExIR::Function.build([], [])
    m.region(0).first_block!.append_operation!(f)

    r = f.region(0)

    b0 = NPC::Block.new.insert_into_region!(r.back)
    b1 = NPC::Block.new.insert_into_region!(r.back)

    b0.append_operation!(NPC::ExIR::Goto.build(b1))

    assert_equal([b1, b0], NPC::PostOrder.new(b0).to_a)
    assert_equal([b1], NPC::PostOrder.new(b1).to_a)
  end

  sig { void }
  def test_diamond_cfg
    m = NPC::ExIR::Module.build
    f = NPC::ExIR::Function.build([], [])
    m.region(0).first_block!.append_operation!(f)
    r = f.region(0)

    b0 = r.first_block!
    b1 = NPC::Block.new
    r.append_block!(b1)

    b2 = NPC::Block.new
    r.append_block!(b2)

    b3 = NPC::Block.new
    r.append_block!(b3)

    t = NPC::ExIR::Const.build(123)

    b0.append_operation!(t)
    b0.append_operation!(NPC::ExIR::GotoIf.build(t.result(0), [b1, b2]))
    b1.append_operation!(NPC::ExIR::Goto.build(b3))
    b2.append_operation!(NPC::ExIR::Goto.build(b3))

    assert_equal([b3, b1, b2, b0], NPC::PostOrder.new(b0).to_a)
    assert_equal([b3, b1], NPC::PostOrder.new(b1).to_a)
    assert_equal([b3, b2], NPC::PostOrder.new(b2).to_a)
    assert_equal([b3], NPC::PostOrder.new(b3).to_a)
  end
end
