# typed: false
# # typed: strict
# frozen_string_literal: true

module NPC
  module WASM
    # class FuncWriter
    #   extend T::Sig
    #   include WASM

    #   sig do
    #     params(
    #       mod: ModuleWriter,
    #       index: Integer,
    #       type: Integer,
    #     ).void
    #   end
    #   def initialize(mod, index, type)
    #     @mod = T.let(mod, ModuleWriter)
    #     @index = T.let(index, Integer)
    #     @type = T.let(type, Integer)

    #     @name = T.let(nil, T.nilable(String))
    #     @locals = T.let([], T::Array[Local])
    #     @exprs = T.let(String.new, String)
    #   end

    #   ### Module back-references

    #   sig { returns(WASM::ModuleWriter) }
    #   attr_reader :mod

    #   sig { returns(Integer) }
    #   attr_reader :index

    #   ## Designate this function as the main entry / initializer for the module
    #   sig { returns(FuncWriter) }
    #   def start
    #     mod.start(self)
    #     self
    #   end

    #   ### Func Type

    #   sig { returns(Integer) }
    #   attr_reader :type

    #   sig { returns(IR::FuncType) }
    #   def type_info
    #     mod.type_info(type)
    #   end

    #   ### Export and Naming

    #   sig { params(name: String).returns(FuncWriter) }
    #   def export(name)
    #     @name = name
    #     mod.export(name, :func, index)
    #     self
    #   end

    #   sig { returns(T.nilable(String)) }
    #   attr_reader :name

    #   sig { returns(T::Boolean) }
    #   def exported?
    #     @name != nil
    #   end

    #   ### Locals

    #   sig { params(type: Symbol, size: Integer).returns(FuncWriter) }
    #   def local(type, size = 1)
    #     @locals << Local.new(type: type, size: size)
    #     self
    #   end

    #   #### Instruction Operations

    #   sig { returns(FuncWriter) }
    #   def i32_add
    #     expr(:i32_add)
    #   end

    #   sig { returns(FuncWriter) }
    #   def i32_sub
    #     expr(:i32_sub)
    #   end

    #   sig { params(value: Integer).returns(FuncWriter) }
    #   def i32_const(value)
    #     expr(:i32_const, value)
    #   end

    #   sig { params(index: Integer).returns(FuncWriter) }
    #   def local_get(index)
    #     expr(:local_get, index)
    #   end

    #   sig { params(index: Integer).returns(FuncWriter) }
    #   def local_set(index)
    #     expr(:local_set, index)
    #   end

    #   sig { returns(FuncWriter) }
    #   def return
    #     expr(:return)
    #   end

    #   ### Finalization and Output

    #   sig { returns(String) }
    #   def build
    #     content = String.new
    #     write_code(content)
    #     content
    #   end

    #   sig { params(out: String).void }
    #   def write_code(out)
    #     locals_bytes = String.new
    #     write_locals(locals_bytes)

    #     exprs_bytes = String.new
    #     write_exprs(exprs_bytes)

    #     write_u64(out, locals_bytes.bytesize + exprs_bytes.bytesize)
    #     write_bytes(out, locals_bytes)
    #     write_bytes(out, exprs_bytes)
    #   end

    #   private

    #   sig { params(out: String).void }
    #   def write_locals(out)
    #     write_u64(out, @locals.count)
    #     @locals.each { |x| write_local(out, x) }
    #   end

    #   sig { params(out: String, x: Local).void }
    #   def write_local(out, x)
    #     write_u64(out, x.size)
    #     write_type_code(out, x.type)
    #   end

    #   sig { params(out: String).void }
    #   def write_exprs(out)
    #     write_bytes(out, @exprs)
    #     write_op_code(out, :end)
    #   end

    #   sig { params(out: String, x: Integer).void }
    #   def write_u64(out, x)
    #     write_bytes(out, ULEB128.encode(x))
    #   end

    #   sig { params(out: String, x: Symbol).void }
    #   def write_op_code(out, x)
    #     write_bytes(out, op_code(x))
    #   end

    #   sig { params(out: String, x: Symbol).void }
    #   def write_type_code(out, x)
    #     write_bytes(out, type_code(x))
    #   end

    #   sig { params(out: String, x: String).void }
    #   def write_bytes(out, x)
    #     out.concat(x)
    #   end

    #   sig do
    #     params(
    #       out: String,
    #       x: T.any(String, Integer),
    #     ).returns(FuncWriter)
    #   end
    #   def write_generic(out, x)
    #     case x
    #     when Integer
    #       write_u64(out, x)
    #     when String
    #       write_bytes(out, x)
    #     end
    #     self
    #   end

    #   ## Write an expression to the expression buffer.
    #   sig do
    #     params(
    #       op: Symbol,
    #       xs: T.any(String, Integer),
    #     ).returns(FuncWriter)
    #   end
    #   def expr(op, *xs)
    #     write_op_code(@exprs, op)
    #     xs.each { |x| write_generic(@exprs, x) }
    #     self
    #   end
    # end
  end
end
