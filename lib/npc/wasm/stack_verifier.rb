# typed: strict
# frozen_string_literal: true

module NPC
  module WASM
    class StackError < Error
      extend T::Sig

      sig { params(operand: Operand, value: Value, cause: Cause).void }
      def initialize(operand, value, cause = nil)
        super(cause)
        @operand = T.let(operand, Operand)
        @value   = T.let(value,   Value)
      end

      sig { returns(Operand) }
      attr_accessor :operand

      sig { returns(Value) }
      attr_accessor :value

      sig { returns(String) }
      def message
        "operand #{operand} does not use value #{value}"
      end
    end

    # The stack verifier walks the operations
    # in a block and checks for invariants
    # 1) every value has exactly one use
    # 2)
    # class StackVerifier
    #   class Stack
    #   end

    #   extend T::Sig

    #   sig { void }
    #   def initialize
    #     @stack = T.let([], T::Array[NPC::Operation])
    #   end

    #   sig { params(block: Block).void }
    #   def verify_block(block)
    #     block.operations.each do |operation|
    #     end
    #   end

    #   def verify_operation(operation)
    #     operation.operands.each do |operand|
    #       a = @stack.pop
    #       b = operand.get
    #       if a != b
    #         return OperationError.new(
    #           operation,
    #           StackError.new(operand, value),
    #         )
    #       end
    #     end

    #     operation.results.each do |result|
    #       @stack.push(result)
    #     end
    #   end
    # end
  end
end
