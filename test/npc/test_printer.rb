# typed: strict
# frozen_string_literal: true

require "npc/test"

class TestPrinter < Minitest::Test
  extend T::Sig

  sig { void }
  def test_print
    m = NPC::ExIR::Module.build

    # Function 1

    f = NPC::ExIR::Function.build
    m.region(0).first_block!.append_operation!(f)

    b1 = NPC::Builder.new(f.region(0).first_block!.front)

    x = b1.insert!(NPC::ExIR::Const.build(123))
    y = b1.insert!(NPC::ExIR::Const.build(456))
    z = b1.insert!(NPC::ExIR::Add.build(x.result(0), y.result(0)))

    block = NPC::Block.new([NPC::ExIR::Num, NPC::ExIR::Num])
    f.region(0).append_block!(block)
    b1.insert!(NPC::ExIR::Goto.build(block, [y.result, z.result]))

    block.append_operation!(NPC::ExIR::Const.build(111))
    block.append_operation!(NPC::ExIR::Return.build([block.argument(0)]))

    # Function 2

    f2 = NPC::ExIR::Function.build
    f2.region(0).first_block!.add_argument(NPC::ExIR::Num)

    m.region(0).first_block!.append_operation!(f2)

    b2 = NPC::Builder.new(f2.region(0).first_block!.front)
    k = b2.insert!(NPC::ExIR::Const.build(789))
    b2.insert!(NPC::ExIR::Return.build([k.result]))

    NPC::Printer.print_operation(m)

    # NPC::Printer.print_block(block)
  end
end
