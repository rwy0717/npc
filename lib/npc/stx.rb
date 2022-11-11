# typed: strict
# frozen_string_literal: true

module NPC
  class << self
    sig { params(input: String).returns(NPC::Operation) }
    def parse_operation(input)
      nil
    end

    sig { params(name: Symbol, type: Type).returns(Spec::Operand) }
    def operand
    end

    sig { params(T::Array[[Symbol, Type]]).returns(Spec::Operands) }
    def operands(operands)
      operands.each do |name, type|
        operand(name, type)
      end
    end

    sig { params(T::Array[]) }
    def operand(name, )
  end

  module Spec
    class Operand
    end
  end
end
