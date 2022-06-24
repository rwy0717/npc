# typed: false
# # typed: true
# frozen_string_literal: true

require_relative("../test")
require("npc")
require("npc/wasm")

module NPC
  module WASM
    class TestSerialization < Minitest::Test
      extend T::Sig

      def test_module
        # mod = IR::Module.new
        # fun = IR::Function.new([IR::I32], [IR::I32])
        #   .insert_into_block!(mod.body_block.back)

        # b = NPC::Builder.at_back(fun.entry_block)

        # constant = b.insert!(IR::Constant.new(IR::I32, 1234))
        # add = b.insert!(IR::Add.new(fun.entry_block.argument(0), constant.result))
        # b.insert!(IR::Return.new([add.result]))

        # Printer.print_operation(mod)
        # Serialize.call(mod, out: File.open("./test.wasm", "w"))
      end
    end
  end
end
