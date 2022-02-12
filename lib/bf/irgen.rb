# typed: strict
# frozen_string_literal: true

require("bf/ir")

module BF
  ## Translates a BF program into IR
  class IRGen
    class << self
      extend T::Sig

      sig { params(prog: String).returns(IR::Program) }
      def run(prog)
        IRGen.new.run(prog)
      end
    end

    extend T::Sig

    sig { params(prog: String).returns(IR::Program) }
    def run(prog)
      program = IR::Program.new
      stack = []
      b = NPC::Builder.at_back(program.body)
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

      program
    end
  end
end
