# typed: strict
# frozen_string_literal: true

module NPC
  # When a pass is run, the result indicates whether the pass was successful or not.
  # Either {Success} or {Failure}.
  module PassResult
    class << self
      extend T::Sig

      # Signal that a pass executed successfully.
      # Preservation indicates what analyses were preserved.
      # By default, preserves no analyses.
      sig { params(preservation: Preservation).returns(Success) }
      def success(preservation = Preservation.none)
        Success.new(preservation)
      end

      # Signal that a pass failed to execute.
      # Optionally include the underlying error.
      sig { params(error: T.nilable(Error)).returns(Failure) }
      def failure(error = nil)
        Failure.new(error)
      end

      # Signal that a pass failed to execute, using an ErrorMessage as the underlying error.
      sig { params(message: String, cause: T.nilable(Error)).returns(Failure) }
      def failure_message(message, cause = nil)
        Failure.new(ErrorMessage.new(message, cause))
      end
    end

    extend T::Sig
    extend T::Helpers
    include Kernel
    sealed!

    # Signal that a pass executed successfully.
    class Success
      extend T::Sig
      include PassResult

      # @param preservation [Preservation] The set of analyses that were preserved by this pass.
      sig { params(preservation: Preservation).void }
      def initialize(preservation = Preservation.none)
        @preservation = T.let(preservation, Preservation)
      end

      sig { returns(Preservation) }
      attr_accessor :preservation
    end

    # Signal that a pass failed to execute.
    class Failure
      extend T::Sig
      include PassResult

      sig { params(error: T.nilable(Error)).void }
      def initialize(error = nil)
        @error = T.let(error, T.nilable(Error))
      end

      sig { returns(T.nilable(Error)) }
      attr_accessor :error
    end
  end

  # A pass that might be run on any operation. "Op agnostic".
  module Pass
    extend T::Sig
    extend T::Helpers
    abstract!

    # Can this pass run on the given operation?
    # sig { abstract.params(operation: Operation).returns(T::Boolean) }
    # def can_run?(operation); end

    # Try to run this pass on the given operation.
    sig { abstract.params(context: PassContext, target: Operation).returns(PassResult) }
    def run(context, target); end

    # Helper to construct a success pass result.
    sig { params(preservation: Preservation).returns(PassResult::Success) }
    def success(preservation = Preservation.none)
      PassResult.success(preservation)
    end

    # Helper to construct a failure pass result.
    sig { params(error: T.nilable(Error)).returns(PassResult::Failure) }
    def failure(error = nil)
      PassResult.failure(error)
    end
  end

  # A pass that only runs on certain operations.

  # Provides access to tracing, analyses, and subpass execution.
  class PassContext
    extend T::Sig

    sig { params(analysis_cache: AnalysisCache).void }
    def initialize(analysis_cache)
      @analysis_cache = T.let(analysis_cache, AnalysisCache)
    end

    # @group running other passes
    # @{

    # run a subpass.
    sig { params(pass: Pass, operation: Operation).void }
    def run_pass(pass, operation)
      # e = verify(operation)
      # raise e if e

      # t0 = Time.now
      # result = pass.run(operation)
      # t1 = Time.now
      # duration = t1 - t0

      # record_trace(block, duration)
      # result
    end

    # run next
    sig { params(pass: Pass, operation: Operation).returns(T.self_type) }
    def run_pass_next(pass, operation)
      self
    end

    # @}

    # @group running analysies
    # @{

    sig do
      type_parameters(:T).params(
        analysis: Analysis[T.type_parameter(:T)],
      ).returns(AnalysisResult[T.type_parameter(:T)])
    end
    def run_analysis(analysis)
      analysis_cache.get(T.unsafe(analysis))
    end

    sig { returns(AnalysisCache) }
    attr_reader :analysis_cache

    # @}
  end

  # A pipeline of passes scheduled to run on a given operation.
  class Plan
    class << self
      extend T::Sig

      sig { params(string: String).returns(Plan) }
      def parse(string)
        from_names(string.split(","))
      end

      sig { params(names: T::Array[String]).returns(Plan) }
      def from_names(names)
        passes = names.map do |name|
          constant = Object.const_get(name) # rubocop:disable Sorbet/ConstantsFromStrings
          raise "#{name} is not a pass" unless constant.is_a?(Pass)

          constant
        end
        Plan.new(passes)
      end
    end

    extend T::Sig

    sig { params(passes: T::Array[Pass]).void }
    def initialize(passes = [])
      @passes = T.let(passes, T::Array[Pass])
    end

    # Append a pass to this plan.
    sig { params(pass: Pass).returns(Pass) }
    def add(pass)
      passes << pass
      pass
    end

    # Create a subplan. Given a target class, run the subplan
    # on every instance of the class.
    sig { params(target_class: Class).returns(Subplan) }
    def nest(target_class)
      subplan = Subplan.new(target_class)
      passes << subplan
      subplan
    end

    sig { returns(T::Array[Pass]) }
    attr_reader :passes

    # Execute this plan on the target operation.
    sig { params(target: Operation).returns(T.nilable(Error)) }
    def run(target)
      context = PassContext.new(
        AnalysisCache.new(target),
      )

      passes.each do |pass|
        result = pass.run(context, target)
        case result
        when PassResult::Failure
          return result.error
        when PassResult::Success
          context.analysis_cache.invalidate(result.preservation)
        end
      end

      nil
    end

    sig { returns(T::Boolean) }
    def empty?
      passes.empty?
    end
  end

  # A collection of passes scheduled to run on the immediate children of an operation.
  class Subplan
    extend T::Sig
    extend T::Helpers
    include Pass

    sig { params(target_class: Class).void }
    def initialize(target_class)
      @target_class = T.let(target_class, Class)
      @passes = T.let([], T::Array[Pass])
    end

    sig { params(pass: Pass).returns(T.self_type) }
    def add(pass)
      @passes << pass
      self
    end

    sig { override.params(context: PassContext, target: Operation).returns(PassResult) }
    def run(context, target)
      target.regions.each do |region|
        region.blocks.each do |block|
          block.operations.each do |operation|
            # TODO: Have to do "run pipeline stuff" here. IE invalidate analysis caches.
            next unless operation.is_a?(@target_class)

            subcontext = PassContext.new(
              context.analysis_cache.child_cache(operation),
            )
            @passes.each do |pass|
              result = pass.run(subcontext, operation)
              return result if result.is_a?(PassResult::Failure)
            end
          end
        end
      end
      # Don't preserve any analyses for the target, we don't know whether
      # they were invalidated by the passes in this subplan.
      success
    end
  end
end
