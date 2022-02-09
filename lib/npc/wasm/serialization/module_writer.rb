# typed: true
# frozen_string_literal: true

# https://webassembly.github.io/spec/core/syntax/instructions.html

module WASM
  class ModuleWriter
    extend T::Sig
    include WASM

    sig { void }
    def initialize
      @functions = []
      @types = FuncTypeTable.new
      @imports = []
      @exports = []
      @start = nil
    end

    ## Introduce a function type into the module, getting back it's type-index.
    ## This is a convenience function that takes two arrays of types, rather than a complete FuncType.
    sig do
      params(
        args: T.any(Symbol, T::Array[Symbol]),
        rets: T.any(Symbol, T::Array[Symbol]),
      ).returns(Integer)
    end
    def type(args, rets)
      intern_type(FuncType.new(args, rets))
    end

    ## Intern a FuncType into this module. If a type index is given, give it right back.
    ##
    sig { params(type: T.any(Integer, FuncType)).returns(Integer) }
    def intern_type(type)
      @types.intern(type)
    end

    ## Look up a function type by index.
    sig { params(index: Integer).returns(FuncType) }
    def type_info(index)
      @types[index]
    end

    def import(_function)
      raise "not implemented"
    end

    sig { params(name: String, type: Symbol, index: Integer).returns(ModuleWriter) }
    def export(name, type, index)
      @exports << Export.new(name: name, type: type, index: index)
      self
    end

    sig { params(function: FuncWriter).returns(ModuleWriter) }
    def start(function)
      @start = function
      self
    end

    sig { params(type: T.any(Integer, FuncType)).returns(FuncWriter) }
    def func(type)
      func = FuncWriter.new(
        self,
        @functions.length,
        intern_type(type),
      )
      @functions.append(func)
      func
    end

    sig { returns(String) }
    def build
      data = String.new
      write_header(data)
      write_type_section(data)
      write_import_section(data)
      write_function_section(data)
      write_table_section(data)
      write_memory_section(data)
      write_global_section(data)
      write_export_section(data)
      write_start_section(data)
      write_element_section(data)
      write_code_section(data)
      # write_data_section(data)
      data
    end

    private

    #### Module Header

    sig { params(out: String).returns(ModuleWriter) }
    def write_header(out)
      write_raw(out, MAGIC)
      write_raw(out, VERSION)
    end

    #### Type Section

    sig { params(out: String).returns(ModuleWriter) }
    def write_type_section(out)
      return self if @types.empty?
      content = String.new
      write_uint(content, @types.length)
      @types.each { |type| write_func_type(content, type) }
      write_section(out, :type, content)
    end

    sig { params(out: String, type: FuncType).returns(ModuleWriter) }
    def write_func_type(out, type)
      write_type_code(out, :func)
      write_result_type(out, type.args)
      write_result_type(out, type.rets)
    end

    sig { params(out: String, result_type: T::Array[Symbol]).returns(ModuleWriter) }
    def write_result_type(out, result_type)
      write_type_vector(out, result_type)
    end

    sig { params(out: String, vector: T::Array[Symbol]).returns(ModuleWriter) }
    def write_type_vector(out, vector)
      write_uint(out, vector.length)
      vector.each do |t|
        write_type_code(out, t)
      end
      self
    end

    sig { params(out: String, type: Symbol).returns(ModuleWriter) }
    def write_type_code(out, type)
      write_raw(out, type_code(type))
      self
    end

    #### Import Section

    sig { params(out: String).returns(ModuleWriter) }
    def write_import_section(out)
      return self if @imports.empty?
      content = String.new
      @imports.each { |i| write_import(content, i) }
      write_section(out, :import, content)
    end

    def write_import(_out, _import)
      return if @imports.empty?
    end

    def write_import_desc(_out, _desc)
    end

    #### Func Section

    def write_function_section(out)
      return if @functions.empty?
      content = String.new
      write_uint(content, @functions.length)
      @functions.each { |f| write_uint(content, f.type) }
      write_section(out, :function, content)
    end

    def write_function_export(data, function)
      write_str(data, function.name)
      write_raw(data, export_code(:func))
      write_uint(data, function.index)
    end

    #### Table Section

    sig { returns(T::Array[Table]) }
    attr_reader :tables

    sig { params(out: String).returns(ModuleWriter) }
    def write_table_section(out)
      content = String.new
      write_uint(content, tables.length)
      @tables.each do |table_type|
        write_table_type(content, table_type)
      end
      write_section(out, :table, content)
      self
    end

    sig { params(out: String, table_type: TableType).returns(ModuleWriter) }
    def write_table_type(out, table_type)
      write_limits(out, table_type.limits)
      write_type_code(out, table_type.elem_type)
      self
    end

    sig { params(out: String, lim: Limits).returns(ModuleWriter) }
    def write_limits(out, lim)
      max = lim.max
      if max
        write_uint(out, 1)
        write_uint(out, lim.min)
        write_uint(out, max)
      else
        write_uint(out, 0)
      end
      self
    end

    #### Memory Section

    def write_memory_section(data)
    end

    #### Global Section

    def write_global_section(data)
    end

    #### Export Section

    sig { params(out: String).returns(ModuleWriter) }
    def write_export_section(out)
      content = String.new
      write_uint(content, @exports.size)
      @exports.each { |x| write_export(content, x) }
      write_section(out, :export, content)
    end

    sig { params(out: String, x: Export).returns(ModuleWriter) }
    def write_export(out, x)
      write_name(out, x.name)
      write_export_code(out, x.type)
      write_uint(out, x.index)
      self
    end

    sig { params(out: String, x: String).returns(ModuleWriter) }
    def write_name(out, x)
      write_uint(out, x.length)
      write_raw(out, x)
      self
    end

    sig { params(out: String, x: Symbol).returns(ModuleWriter) }
    def write_export_code(out, x)
      write_raw(out, export_code(x))
      self
    end

    #### Start Section

    def write_start_section(out)
      return self unless @start
      content = String.new
      write_uint(content, @start.index)
      write_section(out, :start, content)
    end

    def write_element_section(data)
    end

    #### Code Section

    sig { params(out: String).returns(ModuleWriter) }
    def write_code_section(out)
      return self if @functions.empty?
      content = String.new
      write_uint(content, @functions.length)
      @functions.map { |f| f.write_code(content) }
      write_section(out, :code, content)
      self
    end

    sig { params(_data: String).returns(ModuleWriter) }
    def write_data_section(_data)
      raise "not implemented"
    end

    #### Helpers

    # Write out a section and its content.  Will not print the section if the content is empty.
    sig { params(data: String, name: Symbol, content: String).returns(ModuleWriter) }
    def write_section(data, name, content)
      return self if content.empty?
      write_raw(data, WASM.section_code(name))
      write_str(data, content)
      self
    end

    # sig { params(data: String, vec:)}
    # def write_vec(data, vec)
    #   write_uint(data, vec.length)
    #   write_raw(data, vec)
    # end

    sig { params(data: String, str: String).returns(ModuleWriter) }
    def write_str(data, str)
      write_uint(data, str.length)
      write_raw(data, str)
    end

    sig { params(data: String, val: Integer).returns(ModuleWriter) }
    def write_uint(data, val)
      write_raw(data, ULEB128.encode(val))
    end

    sig { params(data: String, val: Integer).returns(ModuleWriter) }
    def write_sint(data, val)
      write_raw(data, SLEB128.encode(val))
    end

    sig { params(data: String, x: String).returns(ModuleWriter) }
    def write_raw(data, x)
      data << x
      self
    end
  end
end
