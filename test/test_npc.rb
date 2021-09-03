# typed: strict
# frozen_string_literal: true

require "npc/test"

class TestNPC < Minitest::Test
  extend T::Sig

  sig { void }
  def test_main
    binding.pry
    region = NPC::Region.new

    assert_empty(region)
    assert_equal(region.front, region.back)
    assert_nil(region.first_block)
    assert_nil(region.last_block)
    assert_equal([], region.arguments)

    block = NPC::Block.new(argument_types: [])
    region.append_block!(block)

    assert_equal(region, block.region)
    assert_equal(region.front, block.prev_link)
    assert_equal(region.front, block.next_link)
    assert_equal(region.back, block)

    assert_equal(block, region.first_block)
    assert_equal(block, region.last_block)
    assert_equal(region.arguments, block.arguments)

    block.drop!

    assert_empty(region)
    assert_equal(region.front, region.back)
    assert_nil(region.first_block)
    assert_nil(region.last_block)

    assert_equal([], region.arguments)
  end

  sig { void }
  def test_operation
    block = NPC::Block.new

    assert_empty(block)
    assert_equal(block.front, block.back)

    operation = NPC::Core::I32Const.new(
      NPC::UnknownLocation.new,
      1234,
    )

    block.append_operation!(operation)

    assert_equal(operation, block.front.next_operation)
    assert_equal(operation, block.back)
  end
end
