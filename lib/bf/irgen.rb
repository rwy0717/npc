# typed: strict
# frozen_string_literal: true

require("bf/ir")

module BF
  ## Translates a BF program into IR
  class ProgramImporter
    # include NPC::Importer
    include Singleton

    extend T::Sig

    sig { params(prog: String).returns(IR::Program) }
    def run(prog)
      program = IR::Program.build
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
