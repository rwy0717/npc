# typed: true
# frozen_string_literal: true

require("npc/wasm")

require_relative("../../test")

class TestReloopPass < MiniTest::Test
  extend T::Sig

  # A plan to run the reloop pass on all functions in a module.
  sig { returns(NPC::Plan) }
  def plan
    plan    = NPC::Plan.new
    subplan = NPC::Subplan.new(NPC::WASM::IR::Function)
    subplan.add(NPC::WASM::ReloopPass.new)
    plan.add(subplan)
    plan
  end

  #
  # No loops or blocks, corner case tests
  #

  def test_single_block
    m = NPC::WASM::IR::Module.build
    f = NPC::WASM::IR::Function.build([], [])
    b = f.entry_block

    p = plan
    error = plan.run(m)
    assert_nil(error)
    NPC::Printer.print_operation(m)
  end

  #
  # Loop Tests
  #

  def test_small_loop_separate_entry
    mod = NPC::WASM::IR::Module.build
    fun = NPC::WASM::IR::Function.build([], [])
    mod.body_block.append_operation!(fun)
    rgn = fun.body_region

    blk0 = rgn.first_block!
    blk1 = NPC::Block.new.insert_into_region!(rgn.back)

    blk0.append_operation!(NPC::WASM::IR::Constant.build(NPC::WASM::IR::I32, 0))
    blk0.append_operation!(NPC::WASM::IR::Goto.build(blk1))

    blk1.append_operation!(NPC::WASM::IR::Constant.build(NPC::WASM::IR::I32, 1))
    blk1.append_operation!(NPC::WASM::IR::Goto.build(blk1))

    NPC::Printer.print_operation(mod)

    error = plan.run(mod)
    p(error) if error
    assert_nil(error)

    NPC::Printer.print_operation(mod)
  end

  #
  # Block Tests
  #

  def test_linear_cfg
    mod = NPC::WASM::IR::Module.build
    fun = NPC::WASM::IR::Function.build([], [])
    mod.body_block.append_operation!(fun)
    rgn = fun.body_region

    blk0 = rgn.first_block!
    blk1 = NPC::Block.new.insert_into_region!(rgn.back)

    blk0.append_operation!(NPC::WASM::IR::Constant.build(NPC::WASM::IR::I32, 0))
    blk0.append_operation!(NPC::WASM::IR::Goto.build(blk1))

    blk1.append_operation!(NPC::WASM::IR::Return.build)

    NPC::Printer.print_operation(mod)

    error = plan.run(mod)
    p(error) if error
    assert_nil(error)
    NPC::Printer.print_operation(mod)
  end

  focus
  def test_diamond_cfg
    mod = NPC::WASM::IR::Module.build
    fun = NPC::WASM::IR::Function.build([], [])

    mod.body_block.append_operation!(fun)

    r = fun.body_region

    b0 = r.first_block!
    b1 = NPC::Block.new.insert_into_region!(r.back)
    b2 = NPC::Block.new.insert_into_region!(r.back)
    b3 = NPC::Block.new.insert_into_region!(r.back)

    const0  = NPC::WASM::IR::Constant.build(NPC::WASM::IR::I32, 0)
    goto_if = NPC::WASM::IR::GotoIf.build(const0.result, b1, b2)

    b0.append_operation!(const0)
    b0.append_operation!(goto_if)

    b1.append_operation!(NPC::WASM::IR::Constant.build(NPC::WASM::IR::I32, 1))
    b1.append_operation!(NPC::WASM::IR::Goto.build(b3))
    b2.append_operation!(NPC::WASM::IR::Constant.build(NPC::WASM::IR::I32, 2))
    b2.append_operation!(NPC::WASM::IR::Goto.build(b3))
    b3.append_operation!(NPC::WASM::IR::Return.build)

    NPC::Printer.print_operation(mod)
    error = plan.run(mod)
    assert_nil(error)
    NPC::Printer.print_operation(mod)
  end
end
