# typed: true
# frozen_string_literal: true

require("leb128")
require("sorbet-runtime")

module WASM
  extend T::Sig

  MAGIC   = T.let("\x00\x61\x73\x6d", String)
  VERSION = T.let("\x01\x00\x00\x00", String)

  SECTION_CODES = T.let({
    custom: "\x0",
    type: "\x1",
    import: "\x2",
    function: "\x3",
    table: "\x4",
    memory: "\x5",
    global: "\x6",
    export: "\x7",
    start: "\x8",
    element: "\x9",
    code: "\xa",
    data: "\xb",
  }.freeze, T::Hash[Symbol, String])

  TYPE_CODES = T.let({
    i32: "\x7f", # -\x01
    i64: "\x7e", # -\x02
    f32: "\x7d", # -\x03
    f64: "\x7c", # -\x04
    anyfunc: "\x70", # -\x10
    func: "\x60", # -\x20
    empty: "\x40", # -\x40
  }.freeze, T::Hash[Symbol, String])

  IMPORT_CODES = T.let({
    func: "\x00",
    table: "\x01",
    mem: "\x02",
    global: "\x03",
  }.freeze, T::Hash[Symbol, String])

  OP_CODES = T.let({
    block: "\x02",
    loop: "\x03",
    end: "\x0b",
    br: "\x0c",
    br_if: "\x0d",
    return: "\x0f",
    local_get: "\x20",
    local_set: "\x21",
    i32_load: "\x28",
    i32_store: "\x36",
    i32_const: "\x41",
    i32_eqz: "\x45",
    i32_add: "\x6a",
    i32_sub: "\x6b",
  }.freeze, T::Hash[Symbol, String])

  EXPORT_CODES = T.let({
    func: "\x00",
    table: "\x01",
    mem: "\x02",
    global: "\x03",
  }.freeze, T::Hash[Symbol, String])

  sig { returns(String) }
  def magic
    MAGIC
  end
  module_function :magic

  sig { returns(String) }
  def version
    VERSION
  end
  module_function :version

  sig { params(name: Symbol).returns(String) }
  def type_code(name)
    TYPE_CODES.fetch(name)
  end
  module_function :type_code

  sig { params(name: Symbol).returns(String) }
  def section_code(name)
    SECTION_CODES.fetch(name)
  end
  module_function :section_code

  sig { params(name: Symbol).returns(String) }
  def import_code(name)
    IMPORT_CODES.fetch(name)
  end
  module_function :import_code

  sig { params(name: Symbol).returns(String) }
  def op_code(name)
    OP_CODES.fetch(name)
  end
  module_function :op_code

  sig { params(name: Symbol).returns(String) }
  def export_code(name)
    EXPORT_CODES.fetch(name)
  end
  module_function :export_code

  ## An immutable representation of a function signature.
  class FuncType
    extend T::Sig

    sig do
      params(
        args: T.any(Symbol, T::Array[Symbol]),
        rets: T.any(Symbol, T::Array[Symbol]),
      ).void
    end
    def initialize(args, rets = [])
      @args = coerce_type_array(args)
      @rets = coerce_type_array(rets)
      freeze
    end

    sig { returns(T::Array[Symbol]) }
    attr_reader :args

    sig { returns(T::Array[Symbol]) }
    attr_reader :rets

    sig { params(other: FuncType).returns(T::Boolean) }
    def ==(other)
      (args == other.args) && (rets == other.rets)
    end

    sig { params(other: FuncType).returns(T::Boolean) }
    def eql?(other)
      self == other
    end

    sig { returns(Integer) }
    def hash
      args.hash ^ rets.hash
    end

    private

    sig { params(x: T.any(Symbol, T::Array[Symbol])).returns(T::Array[Symbol]) }
    def coerce_type_array(x)
      if x.is_a?(Array)
        x.frozen? ? x : x.dup.freeze
      else
        [x]
      end
    end
  end

  sig do
    params(
      args: T.any(Symbol, T::Array[Symbol]),
      rets: T.any(Symbol, T::Array[Symbol])
    ).returns(FuncType)
  end
  def func_type(args, rets = [])
    FuncType.new(args, rets).freeze
  end

  class FuncTypeTable
    extend T::Sig

    # sig { void }
    def initialize
      @index_table = T.let({}, T::Hash[FuncType, Integer])
      @types = T.let([], T::Array[FuncType])
    end

    sig { params(type: T.any(FuncType, Integer)).returns(Integer) }
    def intern(type)
      # type is already an integer
      if type.is_a?(Integer)
        return type
      end

      # type is already interned
      index = @index_table[type]
      return index if index

      # type must be interned
      type = type.frozen? ? type : type.dup.freeze
      index = @index_table.size
      @index_table[type] = index
      @types << type
      index
    end

    sig { params(type: FuncType).returns(T::Boolean) }
    def interned?(type)
      @index_table.key?(type)
    end

    sig { params(block: T.nilable(T.proc.params(x: FuncType).void)).void }
    def each(&block)
      if block_given?
        @types.each(&block)
      else
        @types.each
      end
    end

    sig { params(block: T.nilable(T.proc.params(x: FuncType, i: Integer).void)).void }
    def each_with_index(&block)
      if block_given?
        @types.each_with_index(&block)
      else
        @types.each_with_index
      end
    end

    sig { params(index: Integer).returns(T.nilable(FuncType)) }
    def [](index)
      @types[index]
    end

    sig { returns(Integer) }
    def length
      @types.length
    end

    sig { returns(T::Boolean) }
    def empty?
      @types.empty?
    end

    sig { returns(T::Array[FuncType]) }
    attr_reader :types
  end

  class Export < T::Struct
    prop :name, String
    prop :type, Symbol
    prop :index, Integer
  end

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
    sig do
      params(
        args: T.any(Symbol, T::Array[Symbol]),
        rets: T.any(Symbol, T::Array[Symbol]),
      ).returns(Integer)
    end
    def type(args, rets)
      intern_type(FuncType.new(args, rets))
    end

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

    def write_import(data, import)
    end

    def write_import_desc(out, desc)
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

    def write_table_section(data)
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

  class Local < T::Struct
    prop :type, Symbol
    prop :size, Integer
  end

  class FuncWriter
    extend T::Sig
    include WASM

    sig do
      params(
        mod: ModuleWriter,
        index: Integer,
        type: Integer,
      ).void
    end
    def initialize(mod, index, type)
      @mod = mod
      @type = type
      @index = index
      @name = T.let(nil, T.nilable(String))
      @locals = T.let([], T::Array[Local])
      @exprs = String.new
    end

    ### Module back-references

    sig { returns(ModuleWriter) }
    attr_reader :mod

    sig { returns(Integer) }
    attr_reader :index

    ## Designate this function as the main entry / initializer for the module
    sig { returns(FuncWriter) }
    def start
      mod.start(self)
      self
    end

    ### Func Type

    sig { returns(Integer) }
    attr_reader :type

    sig { returns(FuncType) }
    def type_info
      mod.type_info(type)
    end

    ### Export and Naming

    sig { params(name: String).returns(FuncWriter) }
    def export(name)
      @name = name
      mod.export(name, :func, index)
      self
    end

    sig { returns(T.nilable(String)) }
    attr_reader :name

    sig { returns(T::Boolean) }
    def exported?
      @name != nil
    end

    ### Locals

    sig { params(type: Symbol, size: Integer).returns(FuncWriter) }
    def local(type, size = 1)
      @locals << Local.new(type: type, size: size)
      self
    end

    #### Instruction Operations

    sig { returns(FuncWriter) }
    def i32_add
      expr(:i32_add)
    end

    sig { returns(FuncWriter) }
    def i32_sub
      expr(:i32_sub)
    end

    sig { params(value: Integer).returns(FuncWriter) }
    def i32_const(value)
      expr(:i32_const, value)
    end

    sig { params(index: Integer).returns(FuncWriter) }
    def local_get(index)
      expr(:local_get, index)
    end

    sig { params(index: Integer).returns(FuncWriter) }
    def local_set(index)
      expr(:local_set, index)
    end

    sig { returns(FuncWriter) }
    def return
      expr(:return)
    end

    ### Finalization and Output

    sig { returns(String) }
    def build
      content = String.new
      write_code(content)
      content
    end

    sig { params(out: String).void }
    def write_code(out)
      locals_bytes = String.new
      write_locals(locals_bytes)

      exprs_bytes = String.new
      write_exprs(exprs_bytes)

      write_u64(out, locals_bytes.bytesize + exprs_bytes.bytesize)
      write_bytes(out, locals_bytes)
      write_bytes(out, exprs_bytes)
    end

    private

    sig { params(out: String).void }
    def write_locals(out)
      write_u64(out, @locals.count)
      @locals.each { |x| write_local(out, x) }
    end

    sig { params(out: String, x: Local).void }
    def write_local(out, x)
      write_u64(out, x.size)
      write_type_code(out, x.type)
    end

    sig { params(out: String).void }
    def write_exprs(out)
      write_bytes(out, @exprs)
      write_op_code(out, :end)
    end

    sig { params(out: String, x: Integer).void }
    def write_u64(out, x)
      write_bytes(out, ULEB128.encode(x))
    end

    sig { params(out: String, x: Symbol).void }
    def write_op_code(out, x)
      write_bytes(out, op_code(x))
    end

    sig { params(out: String, x: Symbol).void }
    def write_type_code(out, x)
      write_bytes(out, type_code(x))
    end

    sig { params(out: String, x: String).void }
    def write_bytes(out, x)
      out.concat(x)
    end

    sig do
      params(
        out: String,
        x: T.any(String, Integer),
      ).returns(FuncWriter)
    end
    def write_generic(out, x)
      case x
      when Integer
        write_u64(out, x)
      when String
        write_bytes(out, x)
      end
      self
    end

    ## Write an expression to the expression buffer.
    sig do
      params(
        op: Symbol,
        xs: T.any(String, Integer),
      ).returns(FuncWriter)
    end
    def expr(op, *xs)
      write_op_code(@exprs, op)
      xs.each { |x| write_generic(@exprs, x) }
      self
    end
  end
end
