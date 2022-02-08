# typed: strict
# frozen_string_literal: true

require "npc/test"

class TestPrinter < Minitest::Test
  extend T::Sig

  sig { void }
  def test_print
    m = NPC::Core::Module.new("example")

    # Function 1

    f = NPC::Core::Function.new("test")
    m.region(0).first_block!.append_operation!(f)

    b1 = NPC::Builder.new(f.region(0).first_block!.front)

    x = b1.insert!(NPC::Core::I32Const.new(123))
    y = b1.insert!(NPC::Core::I32Const.new(456))
    z = b1.insert!(NPC::Core::I32Add.new(x.result(0), y.result(0)))

    block = NPC::Block.new([NPC::Core::I32, NPC::Core::I32])
    f.region(0).append_block!(block)
    b1.insert!(NPC::Core::Goto.new(block, [y.result, z.result]))

    block.append_operation!(NPC::Core::I32Const.new(111))
    block.append_operation!(NPC::Core::Return.new(block.argument(0)))

    # Function 2

    f2 = NPC::Core::Function.new("another_test")
    f2.region(0).first_block!.add_argument(NPC::Core::I32)

    m.region(0).first_block!.append_operation!(f2)

    b2 = NPC::Builder.new(f2.region(0).first_block!.front)
    k = b2.insert!(NPC::Core::I32Const.new(789))
    b2.insert!(NPC::Core::Return.new(k.result))

    NPC::Printer.print_operation(m)

    # NPC::Printer.print_block(block)
  end
end
