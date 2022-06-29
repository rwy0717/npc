# typed: true
# frozen_string_literal: true

require_relative("./test")

class TestLoopAnalysis < MiniTest::Test
  def test_minimal_loop
    mod = NPC::ExIR::Module.new
    fun = NPC::ExIR::Function.new
    mod.region(0).first_block!.append_operation!(fun)

    region = fun.region(0)

    b0     = region.first_block!
    b0.append_operation!(NPC::ExIR::Goto.new(b0))

    dominance_info   = NPC::Dominance.new
    loop_info        = NPC::LoopInfo.new(dominance_info)
    region_loop_info = loop_info.for_region(region)

    loop = region_loop_info.loop_for(b0)
    assert(loop)
    return unless loop

    assert_equal([loop], region_loop_info.loops)
    assert_equal([loop], region_loop_info.roots)

    assert_equal(b0, loop.header_block)
    assert_equal([b0], loop.blocks)
    assert_equal([b0], loop.latch_blocks)
    assert_equal([], loop.exit_blocks)
    assert_equal([], loop.exiting_blocks)
    assert_empty(loop.children)
    assert_nil(loop.parent)
  end

  # a test where all the different parts of a loop are different blocks.
  def test_full_loop
    mod = NPC::ExIR::Module.new
    fun = NPC::ExIR::Function.new
    mod.region(0).first_block!.append_operation!(fun)

    region = fun.region(0)

    entering_block = region.first_block!
    header_block   = NPC::Block.new
    interior_block = NPC::Block.new
    latch_block    = NPC::Block.new
    exiting_block  = NPC::Block.new
    exit_block     = NPC::Block.new
  
    entering_block.append_operation!(NPC::ExIR::Goto.new(header_block))
    header_block.append_operation!(NPC::ExIR::Goto.new(interior_block))
    interior_block.append_operation!(NPC::ExIR::Goto.new(exiting_block))
    exiting_block.append_operation!(NPC::ExIR::GotoN.new([latch_block, exit_block]))
    latch_block.append_operation!(NPC::ExIR::Goto.new(header_block))
    exit_block.append_operation!(NPC::ExIR::Return.new)

    region.append_block!(header_block)
    region.append_block!(interior_block)
    region.append_block!(exiting_block)
    region.append_block!(latch_block)
    region.append_block!(exit_block)

    dominance_info   = NPC::Dominance.new
    loop_info        = NPC::LoopInfo.new(dominance_info)
    region_loop_info = loop_info.for_region(region)

    loop = region_loop_info.loop_for(header_block)
    assert(loop)
    assert_nil(region_loop_info.loop_for(entering_block))
    assert_equal(loop, region_loop_info.loop_for(header_block))
    assert_equal(loop, region_loop_info.loop_for(exiting_block))
    assert_equal(loop, region_loop_info.loop_for(latch_block))
    assert_nil(region_loop_info.loop_for(exit_block))
    return unless loop

    assert_equal([loop], region_loop_info.loops)
    assert_equal([loop], region_loop_info.roots)
    assert_equal([header_block, interior_block, exiting_block, latch_block], loop.blocks)

    assert_equal(header_block, loop.header_block)
    assert_equal([latch_block], loop.latch_blocks)
    assert_equal([exiting_block], loop.exiting_blocks)
    assert_equal([exit_block], loop.exit_blocks)
    assert_empty(loop.children)
    assert_nil(loop.parent)
  end
end
