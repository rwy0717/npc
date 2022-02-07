# typed: strict
# frozen_string_literal: true

require_relative("test")

class TestPostOrderBlockSuccessorsIterator < MiniTest::Test
  extend T::Sig

  sig { void }
  def test_straight_line
    m = NPC::Core::Module.new("example")
    f = NPC::Core::Function.new("test")
    m.region(0).first_block!.append_operation!(f)

    r = f.region(0)

    b0 = r.append_block!(NPC::Block.new)
    b1 = r.append_block!(NPC::Block.new)

    b0.append_operation!(NPC::Core::Goto.new(b1))

    iter = NPC::PostOrderBlockSuccessorsIterator.new(b0)
    assert_equal([b1, b0], iter.to_a!)
  end

  sig { void }
  def test_diamond
    m = NPC::Core::Module.new("example")
    f = NPC::Core::Function.new("test")
    m.region(0).first_block!.append_operation!(f)

    r = f.region(0)

    b0 = r.first_block!
    b1 = r.append_block!(NPC::Block.new)
    b2 = r.append_block!(NPC::Block.new)
    b3 = r.append_block!(NPC::Block.new)

    t = NPC::Core::BoolConst.new(true);
    
    b0.append_operation!(t);
    b0.append_operation!(NPC::Core::BranchIf.new(t.result(0), b1, b2))
    b1.append_operation!(NPC::Core::Goto.new(b3))
    b2.append_operation!(NPC::Core::Goto.new(b3))

    iter = NPC::PostOrderBlockSuccessorsIterator.new(b0)
    assert_equal([b3, b1, b2, b0], iter.to_a!)
  end
end
