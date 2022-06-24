# typed: false
# # typed: strict
# frozen_string_literal: true

require_relative("serialization/constants")
require_relative("serialization/export")
require_relative("serialization/func_writer")
require_relative("serialization/func_type_table")
require_relative("serialization/import")
require_relative("serialization/leb128")
require_relative("serialization/limits")
require_relative("serialization/local")
require_relative("serialization/module_writer")
require_relative("serialization/table")
require_relative("serialization/table_type")

module NPC
  module WASM
    # class StackVerifier
    #   extend T::Sig

    #   sig { void }
    #   def initialize
    #   end

    #   get
    # end

    # class Type < T::Struct
    #   const :id, Symbol
    # end

    # I8  = T.let(Type.new(id: :i8))
    # I32 = T.let(Type.new(id: :i32))

    # # A register assignment.
    # module Assignment
    # end

    # # When a value is in the correct location to be
    # class OnStack < T::Struct
    #   include Assignment
    # end

    # # In a local.
    # class InLocal < T::Struct
    #   include Assignment

    #   const :type,  Symbol
    #   const :index, Integer
    # end

    # class LocalAllocator
    #   extend T::Sig

    #   # Simple allocator for local indices.
    #   sig { void }
    #   def initialize
    #     @count = T.let(0, Integer)
    #     @avail = T.let(Set[], T::Array[Integer])
    #   end

    #   sig { returns(Integer) }
    #   def alloc
    #     return @avail.pop if @aval.any?
    #     index = @count
    #     @count += 1
    #     index
    #   end

    #   sig { params(index: Integer).void }
    #   def free(index)
    #     avail << index
    #   end
    # end

    # # Table mapping values to WASM locals.
    # # a value has to be pushed
    # class LocalTable
    #   extend T::Sig

    #   sig { }
    #   def i8

    #   sig { }
    #   def i32
    # end

    # class AssignLocals
    #   sig { }
    #   def initialize
    #     @local_set = T.let(Set[], T::Set[Value])
    #   end

    #   sig { }
    #   def block

    #   # backwards walk in ops
    #   sig { params(block: Block) }
    #   def assign_in_block(block)
    #     operation = block.last_operation
    #     until operation.nil?
    #       assign_results(operation)
    #     end
    #   end

    #   sig { params(operation: Operation).void }
    #   def on_defs(operation)

    #     satisfy_use()
    #     operation.results.each do |result|
    #       next if result.unused?
    #       use = T.must(stack.last)
    #       if use.get == result || on_stack(use.get)
    #         stack.pop
    #       else
    #         assign_register(result)
    #       end
    #     end
    #   end

    #   sig { params(result: Result).void }
    #   def consume

    #   # If the results have any uses, and are in an incorrect location
    #   sig { params(operation: Operation) }
    #   def on_uses(operation)
    #     operation.operands.each do |operand|

    #   end
    # end

    # class Serializer
    #   extend T::Sig

    #   sig { params(mod: IR::Module, out: T.any(StringIO, IO)).void }
    #   def call(mod, out:)
    #     writer = T.let(ModuleWriter.new, ModuleWriter)
    #     write_module(writer, mod)
    #     out.write(writer.build)
    #   end

    #   sig { params(writer: ModuleWriter, mod: IR::Module).void }
    #   def write_module(writer, mod)
    #     puts("write_module")
    #     mod.body_block.operations.each do |operation|
    #       func = T.cast(operation, IR::Function)
    #       write_func(writer.func(func.type), func)
    #     end
    #   end

    #   sig { params(writer: FuncWriter, func: IR::Function).void }
    #   def write_func(writer, func)
    #     puts("write_func")
    #     # func.operations.each do |operation|
    #     #   p operation
    #     # end
    #   end
    # end

    # Serialize = T.let(Serializer.new, Serializer)
  end
end
