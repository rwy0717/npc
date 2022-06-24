# typed: strict
# frozen_string_literal: true
# module NPC
#   class Range
#   end

#   class OperandRange
#     extend T::Sig

#     sig { params(operation: Operation, start: Integer, end: Integer).void }
#     def initialize(operation, start, end)

#     end

#   end

#   class OperandStorage
#   end

#   # A view of the operands in an operation. Provides an easy-to-use API for mutating operand arrays.
#   class OperandsView
#     extend T::Sig

#     sig { params(operation: Operation, index: Integer, length: Integer).void }
#     def initialize(operation, index, length)
#       @operation = T.let(operation, Operation)
#       @start     = T.let(start,     Integer)
#       @end       = T.let
#     end

#     sig { returns(Operation) }
#     def operation
#       @operation
#     end

#     sig { params(index: Integer).returns(Operand) }
#     def get(index)
#     end

#     sig { params(index: Integer).returns(T.nilable(Value)) }
#     def get_value(index)
#       get(index).get
#     end

#     sig { params(index: Integer, value: Value).void }
#     def set!(index, value)
#     end

#     def concat()
#     end

#     sig { params(value: Value).void }
#     def append_value!(value)
#       operation.operand_array
#     end

#     sig { params(values: T::Array[Value]).void }
#     def append_values!(values)
#       operation.value
#     end

#     # Clear the range of operands, erasing the operands from the operand array.
#     sig { void }
#     def clear
#     end
#   end
# end

# operation.operands.append_values!([])
