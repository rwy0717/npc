# typed: strict
# frozen_string_literal: true

module NPC
  class FunctionType
    extend T::Sig
    extend T::Helpers

    sig { params(arguments: T::Array[Type], results: Type).void }
    def initialize(arguments, *results)
      @arguments = T.let(arguments, T::Array[Type])
      @results   = T.let(results,   T::Array[Type])
    end

    sig { returns(T::Array[Type]) }
    attr_accessor :arguments

    sig { returns(Integer) }
    def argument_count
      arguments.length
    end

    sig { params(index: Integer).returns(Type) }
    def argument(index)
      arguments.fetch(index)
    end

    sig { returns(T::Array[Type]) }
    attr_accessor :results

    sig { returns(Integer) }
    def result_count
      results.length
    end

    sig { params(index: Integer).returns(Type) }
    def result(index = 0)
      results.fetch(index)
    end

    sig { params(other: BasicObject).returns(T::Boolean) }
    def ==(other)
      case other
      when FunctionType
        other.arguments == arguments && other.results == results
      else
        false
      end
    end
  end
end
