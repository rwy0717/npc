# typed: false
# frozen_string_literal: true
# module NPC
#   module WASM
#     # An analysis which assigned indices to local variables.
#     class LocalsAnalysis
#       extend T::Sig
#       include Analysis

#       element_type = type_member {{ fixed: Function }}

#       const :target, Operation

#       sig { params(target: Operation).void }
#       def initialize(target: Operation)
#         super(
#           target: target
#         )
#         run
#       end

#       sig { void }
#       def run(target: WASM::Module)
#         def stack_effect
#       end

#       sig { params(function: IR::Function).returns(T.nilable(Error)) }
#       def on_function(function)
#         function.body_region.blocks.each do |block|
#           error = on_block(block)
#           return error if error
#         end
#       end

#       sig { params(block: Block).returns(T.nilable(Error)) }
#       def on_block(block)
#         stack = []
#         block.arguments.each do |argument|
#           if argument.used_once?
#             return Error.new("arg used more than once")
#             stack.push(value)
#           end
#         end

#         block.operations.each do |operation|
#           error = on_operation(operation)
#           return error if error
#         end
#       end

#       sig { params(operation: Operation).returns(T.nilable(Error)) }
#       def on_operation(operation)
#         operation.operands.reverse do |operand|
#           value = stack.pop
#           if value != operand.target
#             return OperationError.new(operation, OperandError(operand))
#           end
#         end

#         operation.results.each do |result|
#           return Error.new("blah") if !result.used_once?
#           stack.push(result)
#         end
#       end
#     end
#   end
# end
