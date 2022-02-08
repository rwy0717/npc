# typed: strict
# frozen_string_literal: true

require("bf/ir")

module BF
  ## Translates a BF program into IR
  class IRGen
    class << self
      extend T::Sig

      sig { params(prog: String).returns(NPC::Core::Module) }
      def run(prog)
        IRGen.new.run(prog)
      end
    end

    extend T::Sig

    sig { params(prog: String).returns(NPC::Core::Module) }
    def run(prog)
      mod = NPC::Core::Module.new("program")
      fun = NPC::Core::Function.new("main")

      mod.body_block.append_operation!(fun)
      stack = []
      b = NPC::Builder.at_back(fun.body_region.first_block!)
      fun = b.insert!(NPC::Core::Function.new("main"))
      i = 0

      while i < prog.length
        case prog[i]
        when ">"
          b.insert!(IR::MoveL.new)
        when "<"
          b.insert!(IR::MoveR.new)
        when "+"
          b.insert!(IR::Inc.new)
        when "-"
          b.insert!(IR::Dec.new)
        when "."
          b.insert!(IR::Print.new)
        when ","
          b.insert!(IR::Read.new)
        when "["
          stack.push(b.insertion_point)
          op = b.insert!(IR::Loop.new)
          b.insertion_point = op.body_region.first_block!.back
        when "]"
          b.insertion_point = stack.pop
        end
        i += 1
      end

      mod
    end
  end
end
