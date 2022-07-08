# typed: true
# frozen_string_literal: true

require("npc/test")

class TestCloning < Minitest::Test
  extend T::Sig
  include NPC

  # The clone is not the same object as the original.
  def test_clone_is_new_object
    op1 = Operation.new
    op2 = Operation.new
    refute_equal(op1, op2)
  end

  # When an operation is cloned, the clone shares the same class.
  def test_clone_operation_subclass
    op1 = ExIR::Add.new
    op2 = op1.clone

    assert_equal(op1.class, op2.class)
  end

  # All attributes have been cloned.
  def test_clone_attributes
    op1 = Operation.new(
      attributes: {
        key1: "value1",
        key2: "value2",
      }
    )
    op2 = op1.clone

    assert_equal("value1", op2.attribute(:key1))
    assert_equal("value2", op2.attribute(:key2))
  end

  # The operands have been cloned, but they should refer to the same values.
  def test_clone_operands
    op0 = Operation.new(results: [nil])
    op1 = Operation.new(operands: [nil, op0.result(0)])
    op2 = op1.clone

    refute_equal(op1.operand(0), op2.operand(0))
    refute_equal(op1.operand(1), op2.operand(1))

    assert_nil(op2.operand(0).get)
    assert_equal(op0.result(0), op2.operand(1).get)
  end

  # The block operands have been cloned, but they should refer to the same blocks.
  def test_clone_block_operands
    bb0 = Block.new
    op1 = Operation.new(block_operands: [nil, bb0])
    op2 = op1.clone

    refute_equal(op1.block_operand(0), op2.block_operand(0))
    refute_equal(op1.block_operand(1), op2.block_operand(1))

    assert_nil(op2.block_operand(0).get)
    assert_equal(bb0, op2.block_operand(1).get)
  end

  # When a graph region is cloned, the clone is also a graph region.
  def test_clone_regions_are_the_right_type
    op1 = Operation.new(regions: [RegionKind::Exec, RegionKind::Decl])
    op2 = op1.clone

    refute_equal(op1.region(0), op2.region(0))
    refute_equal(op1.region(1), op2.region(1))
    assert_equal(Region, op2.region(0).class)
    assert_equal(GraphRegion, op2.region(1).class)
  end

  # When a region is cloned, so are it's blocks.
  def test_clone_regions_with_blocks
    op1      = Operation.new(regions: [RegionKind::Exec])
    region1  = op1.region(0)
    block_a1 = Block.new
    block_b1 = Block.new
    region1.append_block!(block_a1)
    region1.append_block!(block_b1)

    op2      = op1.clone
    region2  = op2.region(0)
    block_a2 = region2.first_block!
    block_b2 = block_a2.next_block!

    refute_equal(region1, region2)
    refute_equal(block_a1, block_a2)
    refute_equal(block_b1, block_b2)
  end

  # When a block is cloned, so are it's operations.
  def test_clone_block_with_operations
    op1       = Operation.new(regions: [RegionKind::Exec])
    region1   = op1.region(0)
    block1    = Block.new
    inner_op1 = Operation.new
    region1.append_block!(block1)
    block1.append_operation!(inner_op1)

    op2       = op1.clone
    region2   = op2.region(0)
    block2    = region2.first_block!
    inner_op2 = block2.first_operation!

    refute_equal(op1, op2)
    refute_equal(region1, region2)
    refute_equal(block1, block2)
    refute_equal(inner_op1, inner_op2)
  end

  # When a block is cloned, its arguments are remapped.
  def test_arguments_are_remapped
    op1       = Operation.new(regions: [RegionKind::Exec])
    region1   = op1.region(0)
    block1    = Block.new([ExIR::Num])
    inner_op1 = Operation.new(operands: [block1.argument(0)])
    region1.append_block!(block1)
    block1.append_operation!(inner_op1)

    op2       = op1.clone
    region2   = op2.region(0)
    block2    = region2.first_block!
    inner_op2 = block2.first_operation!

    assert_equal(block2.argument(0), inner_op2.operand(0).get)
  end

  # When a block is cloned, the results defined inside are remapped.
  def test_results_are_remapped
    op1         = Operation.new(regions: [RegionKind::Exec])
    region1     = op1.region(0)
    block1      = Block.new
    region1.append_block!(block1)
    inner_op_a1 = Operation.new(results: [ExIR::Num])
    block1.append_operation!(inner_op_a1)
    inner_op_b1 = Operation.new(operands: [inner_op_a1.result(0)])
    block1.append_operation!(inner_op_b1)

    op2         = op1.clone
    region2     = op2.region(0)
    block2      = region2.first_block!
    inner_op_a2 = block2.first_operation!
    inner_op_b2 = inner_op_a2.next_operation!

    assert_equal(inner_op_a2.result(0), inner_op_b2.operand(0).get)
  end

  # When a block is cloned, its successors and predecessors are remapped.
  def test_block_operands_are_remapped
    op1      = Operation.new(regions: [RegionKind::Exec])
    region1  = op1.region(0)
    block_a1 = Block.new
    block_b1 = Block.new
    goto1    = ExIR::Goto.build(block_b1)
    region1.append_block!(block_a1)
    region1.append_block!(block_b1)
    block_a1.append_operation!(goto1)

    op2      = op1.clone
    region2  = op2.region(0)
    block_a2 = region2.first_block!
    block_b2 = block_a2.next_block!
    goto2    = block_a2.first_operation!

    assert_equal([block_b2], block_a2.successors)
    assert_equal([block_a2], block_b2.predecessors)
    assert_equal(block_b2,   goto2.block_operand(0).get)
  end
end
