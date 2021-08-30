# typed: strict
# frozen_string_literal: true

require "npc/test"

class TestUse < Minitest::Test
  extend T::Sig

  sig { void }
  def test_use
    value = NPC::Value.new
    use1 = NPC::Use.new(value)
    use2 = NPC::Use.new(value)
    use3 = NPC::Use.new(value)
    assert_equal([use3, use2, use1], value.uses.to_a)
  end
end
