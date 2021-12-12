# typed: strict
# frozen_string_literal: true

require("npc/value")

module NPC

  AnyResult = T.type_alias { T.any(Result, ResultArray) }

  ResultParent = T.type_alias { T.any(ResultArray, Operation) }

  # The result of an operation. An operation may have more than one result.
  class Result < Value
    extend T::Sig

    sig do
      params(
        parent: ResultParent,
        index: Integer,
      ).void
    end
    def initialize(parent, index)
      super()
      @operation = T.let(operation, Operation)
      @index = T.let(index, Integer)
    end

    sig { returns(Operation) }
    attr_reader :operation

    sig { returns(Integer) }
    attr_reader :index

    sig { override.returns(T.nilable(Operation)) }
    def defining_operation
      p = parent
      while p.is_a?(Result)
        p = p.parent
      end
      p
    end
  end

  # A subgroup of results, useful for representing variadic results.
  class ResultArray
    extend T::Sig
    extend T::Helpers
    extend T::Generic

    include Enumerable

    Elem = type_member(fixed: AnyResult)

    sig do
      params(
        parent: ResultParent,
        index: Integer,
      ).void
    end
    def initialize(parent, elements, index)
      @parent   = T.let(parent, ResultParent)
      @index    = T.let(index, Integer)
      @elements = T.let([], T::Array[Result])
    end

    ### Accessing the parents

    sig { returns(ResultParent) }
    attr_accessor :parent

    sig { returns(Operation) }
    def defining_operation
      p = @parent
      until p.is_a?(Operation)
        p = p.parent
      end
      p
    end

    ### Accessing subresults

    # The underlying elements of this 
    sig { returns(T::Array[AnyResult]) }
    attr_reader :elements

    sig { params(index: Integer).returns(T.nilable(AnyResult)) }
    def [](index)
      @elements[index]
    end

    sig { params(T.proc.params(arg0: AnyResult).void).void }
    def each(&proc)
      @elements.each(&proc)
    end

    ### Adding and removing subresults

    # Append a new Result.
    sig { returns(Result) }
    def new_result
      result = Result.new(self, elements.length)
      @elements << result
      result
    end

    # Append a new ResultArray.
    sig { returns(ResultArray) }
    def new_result_array
      result = ResultArray.new(self, elements.length)
      @elements << result
      result
    end

    ### Cloning and copying

    # Create a copy of this result array underneath the given parent.
    sig { params(parent: ResultParent).returns(ResultArray) }
    def copy_under(parent)
      copy = parent.new_result_array
      each do |element|
        element.copy_under(copy)
      end
      copy
    end

    ### Drop

    # Recursively drop all uses of the results in this result-array.
    sig { void }
    def drop_uses!
      each do |element|
        element.drop_uses!
      end
    end
  end
 end
end

