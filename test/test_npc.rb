# typed: false
# frozen_string_literal: true

require "npc/test"

class TestNPC < Minitest::Test
  extend T::Sig

  # class Const < NPC::Operation
  #   define do
  #   end

  #   sig { params(value: Integer).void }
  #   def initialize(value)
  #     super(results: [NPC::Core::I32])
  #     @value = T.let(value, Integer)
  #   end

  #   sig { returns(Integer) }
  #   attr_accessor :value
  # end

  # class Add < NPC::Operation
  #   define do
  #     operand(:lhs)
  #     operand(:rhs)
  #   end
  # end

  # sig { void }
  # def test_accessors
  #   k = Const.new(123)
  #   add = Add.new
  #   add.lhs = k.result(0)
  #   add.rhs = k.result(0)

  #   assert_equal(add.lhs, add.rhs)
  # end

  # sig { void }
  # def test_main
  #   region = NPC::Region.new

  #   assert_empty(region)
  #   assert_equal(region.front, region.back)
  #   assert_nil(region.first_block)
  #   assert_nil(region.last_block)
  #   assert_empty(region)
  #   assert_equal(region.front, region.back)
  #   assert_nil(region.first_block)
  #   assert_nil(region.last_block)

  #   assert_empty(region.arguments)
  # end

  # sig { void }
  # def test_operation
  #   block = NPC::Block.new

  #   assert_empty(block)
  #   assert_equal(block.front, block.back)

  #   operation = NPC::Core::I32Const.new(1234)

  #   block.append_operation!(operation)

  #   assert_equal(operation, block.front.next_operation)
  #   assert_equal(operation, block.back)
  # end

  # sig { void }
  # def test_fold
  #   b = Builder.new
  #   b.insert(NPC::Core::Module.new)
end
