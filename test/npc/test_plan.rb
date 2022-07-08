# typed: true
# frozen_string_literal: true

require "npc/test"
require "singleton"

class TestPass < Minitest::Test
  extend T::Sig

  class BogusResult
  end

  class BogusAnalysis
    extend T::Sig
    extend T::Helpers
    extend T::Generic
    include NPC::Analysis
    include Singleton

    Value = type_member { { fixed: BogusResult } }

    sig do
      override.params(
        context: NPC::AnalysisContext,
        operation: NPC::Operation,
      ).returns(NPC::AnalysisResult[Value])
    end
    def run(context, operation)
      puts("run #{self.class.name} on #{operation}")
      NPC::AnalysisResult.success(BogusResult.new)
    end
  end

  class BogusPass
    extend T::Sig
    include NPC::Pass

    sig { override.params(context: NPC::PassContext, operation: NPC::Operation).returns(NPC::PassResult) }
    def run(context, operation)
      puts("run #{self.class.name} on #{operation}")
      result = context.run_analysis(BogusAnalysis.instance)
      p(result)
      success(NPC::Preservation.all)
    end
  end

  sig { void }
  def test_plan
    pass = BogusPass.new
    plan = NPC::Plan.new
    plan.add(pass)

    subplan = plan.nest(NPC::ExIR::Function)
    subplan.add(pass)
    subplan.add(pass)

    plan.add(pass)

    mod = NPC::ExIR::Module.build
    fun = NPC::ExIR::Function.build
    mod.body_block.append_operation!(fun)

    plan.run(mod)
  end
end
