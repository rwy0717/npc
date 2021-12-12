# typed: strict
# frozen_string_literal: true

require("npc/use")

module NPC
  class Operator; end
  class Operand < Use; end
  class OperandArray; end

  AnyOperand = T.type_alias { T.any(Operand, OperandArray) }

  OperandParent = T.type_alias { T.any(Operator, OperandArray) }

  # An input to an operation, and a reference to a value.
  class Operand < Use
    extend T::Sig
    
    sig do
      params(
        parent: OperandParent,
        index: Integer,
        value: T.nilable(Value),
      ).void
    end
    def initialize(parent, index, value = nil)
      super(value)
      @parent = T.let(parent, OperandParent)
      @index  = T.let(index,  Integer)
    end

    # The parent structure that this operand is a part of.
    sig { returns(OperandParent) }
    attr_reader :parent

    # The index of this operand in the operation.
    sig { returns(Integer) }
    attr_reader :index

    # The parent operation that this operand is a part of.
    sig { returns(Operation) }
    def operation
      p = @parent
      until p.is_a?(Operation)
        p = p.parent
      end
      p
    end

    sig do
      type_parameters(:T)
        .params(
          proc: T.proc.params(arg0: Operand).returns(T.type_parameter(:T)))
        .returns(T.type_parameter(:T))
    end
    def walk_operands(&proc)
      proc.call(self)
    end

    sig { returns(String) }
    def to_s
      "(operand #{value})"
    end

    sig { params(parent: OperandParent).returns(Operand) }
    def copy_under(parent)
      parent.new_operand(@value)
    end
  end

  # A variadic input into an operation.
  class OperandArray
    extend T::Sig
    extend T::Helpers

    sig do
      params(
        parent: OperandParent,
        index: Integer,
      ).void
    end
    def initialize(parent, index, values = [])
      @parent = T.let(parent, OperandParent)
      @index = T.let(index, Integer)
      @elements = T.let([], T::Array[AnyOperand])
    end

    sig { returns(OperandParent) }
    attr_reader :parent

    sig { returns(Operation) }
    def operation
      p = @parent
      p = p.parent until p.is_a?(Operation)
    end

    sig { returns(Integer) }
    attr_reader :index

    sig { returns(T::Array[Suboperand]) }
    attr_reader :elements

    sig do
      .params(
        proc: T.proc.params(arg0: Operand).returns(T.untyped)
      ).returns(T::Array[T.untyped])
    end
    def walk_operands(&proc)
      @elements.map do |e|
        e.walk_operands(&proc)
      end
    end

    # Create a deep copy of this operand underneath the given parent.
    sig { params(OperandParent).returns(OperandArray) }
    def copy_under(parent)
      copy = parent.new_operand_array
      @elements.each do |element|
        element.copy_under(copy)
      end
      copy
    end

    # Recursively clear this operand array, keeping the suboperands in place.
    sig { override.void }
    def drop!
      @elements.each(&:drop)
    end
  end
end

