# typed: true
# frozen_string_literal: true

# module BF
#   extend T::Sig

#   class State < T::Struct
#     const :prog, String
#     const :istr, String

#     prop :data, T::Array[Integer], factory: -> { [] }
#     prop :ostr, String, factory: -> { "" }

#     prop :prog_index, Integer, default: 0
#     prop :data_index, Integer, default: 0
#     prop :istr_index, Integer, default: 0
#   end

#   class Interpreter < State
#     class << self
#       extend T::Sig
#       sig do
#         params(
#           prog: String,
#           istr: String,
#         ).returns(String)
#       end
#       def call(prog, istr = "")
#         interpreter = self.new(prog: prog, istr: istr)
#         interpreter.run
#         interpreter.ostr
#       end
#     end

#     sig do
#       void
#     end
#     def call
#     while prog_index < prog.length
#       case prog[prog_index]
#       when '>'
#         data_index += 1
#       when '<'
#         data_index -= 1
#       when '+'
#         data[data_index] = (data[data_index] || 0) + 1
#       when '-'
#         data[data_index] = (data[data_index] || 0) - 1
#       when '.'
#         ostr << data.fetch(data_index, 0).abs.chr
#       when ','
#         if istr_index < istr.length
#           data[data_index] = istr[istr_index]
#           istr_index += 1
#         else
#           data[data_index] = 0
#         end
#       when '['
#         if data[data_index] == 0
#           depth = 1
#           until depth == 0
#             prog_index += 1
#             if prog[prog_index] == ']'
#               depth -= 1
#             elsif prog[prog_index] == '['
#               depth += 1
#             end
#           end
#         end
#       when ']'
#         if data[data_index] != 0
#           depth = 1
#           until depth == 0
#             prog_index -= 1
#             if prog[prog_index] == ']'
#               depth += 1
#             elsif prog[prog_index] == '['
#               depth -= 1
#             end
#           end
#         end
#       end
#       prog_index += 1
#     end
#     nil
#   end
# end
