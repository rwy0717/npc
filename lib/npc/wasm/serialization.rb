# typed: strict
# frozen_string_literal: true

require_relative("serialization/constants")
require_relative("serialization/export")
require_relative("serialization/func_type")
require_relative("serialization/func_type_table")
require_relative("serialization/func_writer")
require_relative("serialization/import")
require_relative("serialization/leb128")
require_relative("serialization/limits")
require_relative("serialization/local")
require_relative("serialization/module_writer")
require_relative("serialization/table")
require_relative("serialization/table_type")

module NPC
  module WASM
    class LocalAllocator
      extend T::Sig

      # Simple allocator for local indices.
      sig { void }
      def initialize
        @count = T.let(0, Integer)
        @avail = T.let(Set[], T::Array[Integer])
      end

      sig { returns(Integer) }
      def alloc
        return @avail.pop if @aval.any?
        index = @count
        @count += 1
        index
      end

      sig { params(index: Integer).void }
      def free(index)
        avail << index
      end
    end

    # Table mapping values to WASM locals.
    # a value has to be pushed
    class LocalTable
      extend T::Sig

      sig { }
      def i8
      def i32
    end

    class AssignLocals
      sig { }

      assign_in_block()
    end

    class Serializer
      class << self
        extend T::Sig

        sig { params(mod: IR::Module, out: T.any(StringIO, IO)) }
        def call(mod, out:)
          Serializer.new(out: out).call(mod)
        end

        sig { returns }
        def serialize_function(fun: IR::Function, out: 
        end
      end

      extend T::Sig

      sig { params(out: T.any(StringIO, IO)).void }
      def initialize(out:)
        @out = T.let(out, T.any(StringIO, IO))
        @module_writer = T.let(ModuleWriter.new)
      end

      sig { params(fun: IR::Function) }
      def on_function(fun)
        FuncWriter.new(

        )

        fun.operations.each do |operation|
        end
      end
    end
  end
end
