# typed: strict
# frozen_string_literal: true

module NPC
  # A record of what analyses are preserved by a pass.
  #
  # Preservation sets come in three types:
  # - {None}: all analyses are unconditionally invalidated. This is the default.
  # - {All}:  all analyses remain valid.
  # - {Some}: only some analyses will remain valid.
  #
  # When a pass succeeds by {PassResult::Success},
  # it can provide a preservation set.
  module Preservation
    class << self
      extend T::Sig

      # Create a preservation set where all analyses are preserved.
      sig { returns(All) }
      def all
        All.new
      end

      # Create a preservation set where no analysis is preserved.
      sig { returns(None) }
      def none
        None.new
      end

      # Create a preservation set where some analyses are preserved.
      sig { params(set: T::Set[GenericAnalysis]).returns(Some) }
      def some(set = Set[])
        Some.new(set)
      end
    end

    extend T::Sig
    extend T::Helpers
    include Kernel
    abstract!
    sealed!

    # True if the preservation set includes the given analysis.
    #
    # @note Users should not need to explicitly test for validity. Analyses are automatically
    #       invalidated after a pass has run.
    #
    # An analysis may still be valid, even if it's not preserved.
    # And in the opposite case, an analysis may be invalid, even if it's preserved.
    # The correct way to test for validity is to call +analysis.valid?(perservation)+.
    #
    # @see NPC::GenericAnalysis
    sig { abstract.params(analysis: GenericAnalysis).returns(T::Boolean) }
    def preserved?(analysis); end

    # All Analyses were preserved, no analysis was invalidated.
    class All
      extend T::Sig
      extend T::Helpers
      include Preservation
      final!

      sig(:final) { override.params(analysis: GenericAnalysis).returns(T::Boolean) }
      def preserved?(analysis)
        true
      end
    end

    # No analysis was preserved, all analyses are invalidated.
    class None
      extend T::Sig
      extend T::Helpers
      include Preservation
      final!

      sig(:final) { override.params(analysis: GenericAnalysis).returns(T::Boolean) }
      def preserved?(analysis)
        false
      end
    end

    # Some analyses are preserved.
    # Lists the analyses that were explicitly preserved by the pass.
    # All other analyses are invalidated.
    class Some
      extend T::Sig
      extend T::Helpers
      include Preservation
      final!

      sig(:final) { params(analyses: T::Set[GenericAnalysis]).void }
      def initialize(analyses = Set[])
        @analyses = T.let(analyses, T::Set[GenericAnalysis])
      end

      sig(:final) { returns(T::Set[GenericAnalysis]) }
      attr_reader :analyses

      sig(:final) { override.params(analysis: GenericAnalysis).returns(T::Boolean) }
      def preserved?(analysis)
        analyses.include?(analysis)
      end

      sig(:final) { params(analysis: GenericAnalysis).void }
      def add(analysis)
        analyses.add(analysis)
      end

      sig(:final) { params(analysis: GenericAnalysis).void }
      def delete(analysis)
        analyses.delete(analysis)
      end
    end
  end

  module AnalysisResult
    class << self
      extend T::Sig

      sig do
        type_parameters(:T)
          .params(
            value: T.type_parameter(:T),
          ).returns(Success[T.type_parameter(:T)])
      end
      def success(value)
        Success.new(value)
      end

      sig do
        type_parameters(:T)
          .params(
            error: Error,
          ).returns(Failure[T.type_parameter(:T)])
      end
      def failure(error)
        Failure.new(error)
      end
    end

    extend T::Sig
    extend T::Helpers
    extend T::Generic
    include Kernel
    interface!
    sealed!

    Value = type_member

    sig { abstract.returns(T::Boolean) }
    def success?; end

    sig { abstract.returns(T::Boolean) }
    def failure?; end

    sig { abstract.returns(Value) }
    def value!; end

    sig { abstract.returns(T.nilable(Error)) }
    def error!; end

    # The analysis completed successfully.
    # The success object contains the results of the analysis.
    # The result will be cached until the analysis is invalidated.
    class Success
      extend T::Sig
      extend T::Helpers
      extend T::Generic
      include AnalysisResult
      final!

      Value = type_member

      sig(:final) { params(value: Value).void }
      def initialize(value)
        @value = T.let(value, Value)
      end

      sig(:final) { override.returns(T::Boolean) }
      def success?
        true
      end

      sig(:final) { override.returns(T::Boolean) }
      def failure?
        false
      end

      sig(:final) { override.returns(Value) }
      def value!
        @value
      end

      sig(:final) { override.returns(T.nilable(Error)) }
      def error!
        raise "Result is not a failure"
      end

      sig(:final) { returns(Value) }
      attr_reader :value
    end

    # The analysis failed. Optionally contains an error.
    # A failure result won't be cached.
    class Failure
      extend T::Sig
      extend T::Helpers
      extend T::Generic
      include AnalysisResult
      final!

      Value = type_member

      sig(:final) { params(error: Error).void }
      def initialize(error)
        @error = T.let(error, Error)
      end

      sig(:final) { override.returns(T::Boolean) }
      def success?
        false
      end

      sig(:final) { override.returns(T::Boolean) }
      def failure?
        true
      end

      sig(:final) { override.returns(Value) }
      def value!
        raise "Result is not a success"
      end

      sig(:final) { override.returns(T.nilable(Error)) }
      def error!
        @error
      end

      sig(:final) { returns(T.nilable(Error)) }
      attr_reader :error
    end
  end

  module GenericAnalysis
    extend T::Sig
    extend T::Helpers
    abstract!

    # Is this analysis valid, given a set of preserved analyses.
    sig { overridable.params(preservation: Preservation).returns(T::Boolean) }
    def valid?(preservation)
      # The default implementation just checks that this analysis is
      # in the preservation set. This can be overridden to check for
      # dependencies or base validity on other external flags.
      #
      # TODO: Should we just track analysis dependencies, and say that
      # an analysis is valid if it, and it's dependencies, are all preserved?
      preservation.preserved?(self)
    end

    # Is this analysis invalid, given a set of some preserved analyses?
    sig(:final) { params(preservation: Preservation).returns(T::Boolean) }
    def invalid?(preservation)
      !valid?(preservation)
    end
  end

  class AnalysisContext
    extend T::Sig

    sig { params(analysis_cache: AnalysisCache).void }
    def initialize(analysis_cache)
      @analysis_cache = T.let(analysis_cache, AnalysisCache)
    end

    sig do
      type_parameters(:T).params(
        analysis: Analysis[T.type_parameter(:T)],
      ).returns(AnalysisResult[T.type_parameter(:T)])
    end
    def run_analysis(analysis)
      @analysis_cache.get(analysis)
    end
  end

  module Analysis
    extend T::Sig
    extend T::Helpers
    extend T::Generic
    include GenericAnalysis
    abstract!

    Value = type_member(:out)

    # Run this analyses. The results might be cached.
    # TODO: Should this be called "call"?
    sig { abstract.params(context: AnalysisContext, operation: Operation).returns(AnalysisResult[Value]) }
    def run(context, operation); end
  end

  # A per-operation cache of analysis results.
  class AnalysisCache
    extend T::Sig
    extend T::Helpers

    # Construct a cache of analysis results for the given operation.
    sig { params(operation: Operation).void }
    def initialize(operation)
      @operation    = T.let(operation, Operation)
      @cache        = T.let({}, T::Hash[GenericAnalysis, T.untyped])
      @child_caches = T.let({}, T::Hash[Operation, AnalysisCache])
    end

    # Get an analysis result, either by recomputing, or from the cache.
    # TODO: Rename this to get_analysis
    sig do
      type_parameters(:T).params(
        analysis: Analysis[T.type_parameter(:T)],
      ).returns(AnalysisResult[T.type_parameter(:T)])
    end
    def get(analysis)
      cached = get_cached(analysis)
      return cached if cached

      context = AnalysisContext.new(self)
      result = analysis.run(context, @operation)
      @cache[analysis] = result if result.is_a?(AnalysisResult::Success)
      result
    end

    # Get an analysis result if it's already cached.
    sig do
      type_parameters(:T)
        .params(
          analysis: Analysis[T.type_parameter(:T)],
        ).returns(T.nilable(AnalysisResult::Success[T.type_parameter(:T)]))
    end
    def get_cached(analysis)
      @cache[analysis]
    end

    # Get an analysis result for a child operation.
    # The given operation must be an immediate child of our main operation.
    # TODO: Should have a variant that can build a cache for non-immediate children.
    sig do
      type_parameters(:T)
        .params(
          analysis: Analysis[T.type_parameter(:T)],
          child: Operation,
        ).returns(AnalysisResult[T.type_parameter(:T)])
    end
    def get_for_child(analysis, child)
      child_cache(child).get(analysis)
    end

    # Get or construct a cache for a child operation.
    # The given operation must be an immediate child of our main operation.
    sig { params(operation: Operation).returns(AnalysisCache) }
    def child_cache(operation)
      if operation.parent_operation != @operation
        raise "#{operation} is not a child of #{@operation}"
      end

      @child_caches[operation] ||= AnalysisCache.new(operation)
    end

    # Invalidate this cache and all subcaches.
    sig { params(preservation: Preservation).void }
    def invalidate(preservation)
      case preservation
      when Preservation::All
        # All results are preserved, do nothing.
      when Preservation::None
        # No results are preserved, drop everything.
        @cache.clear
        @child_caches.each do |_operation, cache|
          cache.invalidate(preservation)
        end
      when Preservation::Some
        @cache.each do |analysis, _result|
          invalidate_analysis(analysis, preservation)
        end
        @child_caches.each do |_operation, child_cache|
          child_cache.invalidate(preservation)
        end
      end
    end

    private

    # Try to invalidate an analysis result.
    # If the analysis indicates that it's valid, we ensure it's in the preservation set.
    # If the analysis indicates that it's invalid, we remove it from the preservation set.
    sig { params(analysis: GenericAnalysis, preservation: Preservation::Some).void }
    def invalidate_analysis(analysis, preservation)
      # This is wierd.
      # We ask the analysis if, given the preservation set, was the analysis invalidated.
      if analysis.valid?(preservation)
        preservation.add(analysis)
      else
        preservation.delete(analysis)
        @cache.delete(analysis)
      end
    end
  end
end

require_relative("analysis/dominance.rb")
require_relative("analysis/loop.rb")
