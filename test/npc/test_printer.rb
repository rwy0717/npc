# typed: strict
# frozen_string_literal: true

require "npc/test"

class TestPrinter < Minitest::Test
  extend T::Sig
  include NPC

  sig { void }
  def test_print
    m = ExIR::Module.build

    # Function 1

    f = ExIR::Function.build
    m.region(0).first_block!.append_operation!(f)

    b1 = Builder.new(f.region(0).first_block!.front)

    x = b1.insert!(ExIR::Const.build(123))
    y = b1.insert!(ExIR::Const.build(456))
    z = b1.insert!(ExIR::Add.build(x.result(0), y.result(0)))

    block = Block.new([ExIR::Num, ExIR::Num])
    f.region(0).append_block!(block)
    b1.insert!(ExIR::Goto.build(block, [y.result, z.result]))

    block.append_operation!(ExIR::Const.build(111))
    block.append_operation!(ExIR::Return.build([block.argument(0)]))

    # Function 2

    f2 = ExIR::Function.build
    f2.region(0).first_block!.add_argument(ExIR::Num)

    m.region(0).first_block!.append_operation!(f2)

    b2 = Builder.new(f2.region(0).first_block!.front)
    k = b2.insert!(ExIR::Const.build(789))
    b2.insert!(ExIR::Return.build([k.result]))

    Printer.print_operation(m)

    # NPC::Printer.print_block(block)
  end
end
