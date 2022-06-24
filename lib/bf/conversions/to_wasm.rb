# typed: false
# # # typed: strict
# frozen_string_literal: true
# # frozen_string_literal: true

# module BF
#   class ToWASM
#     extend T::Sig

#     sig { void }
#     def initialize
#       @import_table = T.let({}, T::Hash[Symbol, NPC::WASM::Import])
#     end

#     # #
#     # # Build a module with a memory for the
#     # #
#     # sig { returns(NPC::WASM::Module) }
#     # def build_module
#     #   m = NPC::WASM::Module.new
#     # end

#     # Create the imports that we need
#     sig { params(symbol: Symbol).returns(NPC::WASM::Import) }
#     def import
#       @import_table[symbol] ||= NPC::WASM::Import.new(symbol)
#     end

#     sig { params(program: IR::Program) }
#     def call(program)
#       mod = NPC::WASM::IR::Module.new
#       fun = NPC::WASM::IR::Function.new.insert_into_block!(mod.body_block.back)
#       mem = NPC::WASM::IR::Memory.new.insert_into_block!(mod.body_block.back)

#       b = NPC::Builder.new(fun.entry_block.back)

#       program.body_block.each do |operation|
#         emit(b, operation)
#       end
#     end

#     sig { params(b: NPC::Builder, operation: NPC::Operation).void }
#     def emit(b, operation)
#       case operation
#       # when IR::Inc
#       #   # load data pointer
#       #   # index off it to load from memory
#       #   data_ptr = b.insert!(NPC::WASM::IR::GetLocal.new(0))
#       #   data     = b.insert!(NPC::WASM::IR::I32Load.new(data_ptr))
#       #   amount   = b.insert!(NPC::WASM::IR::I32Const.new(operation.amount))
#       #   new_data = b.insert!(NPC::WASM::IR::I32Add.new(x.result, y.result))
#       #   b.insert!(NPC::WASM::SetLocal)
#       # when IR::Dec
#       #   x = b.insert!(NPC::WASM::IR::GetLocal.new(0))
#       #   y = b.insert!(NPC::WASM::IR::I32Const.new(operation.amount))
#       #   b.insert!(NPC::WASM::IR::I32Add.new(x, y))
#       # when IR::MoveL
#       #   x = b.insert!(NPC::WASM::IR::GetLocal.new(0))
#       #   y = b.insert!(NPC::WASM::IR::I32Const.new(operation.amount))
#       #   b.insert!(NPC::WASM::IR::I32Add.new(x, y))
#       # when IR::MoveR
#       #   x = b.insert!(NPC::WASM::IR::GetLocal.new(0))
#       #   y = b.insert!(NPC::WASM::IR::I32Const.new(operation.amount))
#       #   b.insert!(NPC::WASM::IR::I32Add.new(x, y))
#       when IR::Loop
#       else
#         raise "unhandled BF IR operation"
#       end
#     end
#   end
# end
