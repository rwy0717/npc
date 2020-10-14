# typed: true
# frozen_string_literal: true
# frozen_string_literals: true

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

  INSTRUCTION_CODES = T.let({
    block: "\x02",
    loop: "\x03",
    end: "\x0b",
    br: "\x0c",
    br_if: "\x0d",
    return: "\x0f",
    get_local: "\x20",
    set_local: "\x21",
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
  def instruction_code(name)
    INSTRUCTION_CODES.fetch(name)
  end
  module_function :instruction_code

  sig { params(name: Symbol).returns(String) }
  def export_code(name)
    EXPORT_CODES.fetch(name)
  end
  module_function :export_code

  class ModuleWriter
    extend T::Sig
    include WASM

    sig { void }
    def initialize
      @functions = []
      @types = Set.new
      @imports = []
      @exports = []
      @start = nil
    end

    sig { params(input: T::Array[Symbol], output: T::Array[Symbol]).returns(Integer) }
    def type(input, output)
      index = @types.length
      @types.append([input, output])
      index
    end

    def import(_function)
      raise "not implemented"
    end

    sig { params(function: FunctionWriter).void }
    def start(function)
      @start = function
      self
    end

    sig do
      params(name: String, type: T.untyped, nlocals: Integer).returns(FunctionWriter)
    end
    def function(name, type, nlocals = 0)
      index = @functions.length
      f = FunctionWriter.new(name, type, index, nlocals)
      @functions.append(f)
      f
    end

    sig { returns(String) }
    def build
      data = ''
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
      write_data_section(data)
      data
    end

    private

    sig { params(data: String).returns(ModuleWriter) }
    def write_header(data)
      write_raw(data, MAGIC)
      write_raw(data, VERSION)
    end

    sig { params(data: String).void }
    def write_type_section(data)
      content = ''
      write_uint(content, @types.length)
      @types.map { |type| write_type(content, type) }
      write_section(data, :type, content)
    end

    sig { params(data: String, type: T.untyped).void }
    def write_type(data, type)
      return if @types.empty?

      write_raw(data, WASM.type_code(:func))

      ins = type[0]
      write_raw(data, ins.length)
      ins.map { |t| write_raw(data, WASM.type_code(t)) }

      outs = type[1]
      write_raw(data, outs.length)
      outs.map { |t| write_raw(data, WASM.type_code(t)) }
    end

    def write_import_section(_data)
      return if @imports.empty?
    end

    def write_import(data, import)
    end

    def write_function_section(data)
      return if @functions.empty?
      content = ''
      write_uint(content, @functions.length)
      @functions.map { |f| write_raw(content, f.type) }
      write_section(data, :function, content)
    end

    def write_function_export(data, function)
      write_str(data, function.name)
      write_raw(data, export_code(:func))
      write_uint(data, function.index)
    end

    def write_table_section(data)
    end

    def write_memory_section(data)
    end

    def write_global_section(data)
    end

    sig { params(data: String).returns(ModuleWriter) }
    def write_export_section(data)
      content = ''

      # export functions
      #      @exports.map {|f| write_export(content, f) if f.export }

      write_section(data, :export, content)
    end

    def write_start_section(data)
      content = ''
      write_uint(content, @start.index)
      write_section(data, :start, content)
    end

    def write_element_section(data)
    end

    sig { params(data: String).returns(ModuleWriter) }
    def write_code_section(data)
      return self if @functions.empty?
      content = ''
      write_uint(content, @functions.length)
      @functions.map { |f| write_raw(content, f.build) }
      write_section(data, :code, content)
      self
    end

    sig { params(_data: String).returns(ModuleWriter) }
    def write_data_section(_data)
      raise "not implemented"
    end

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
      data.concat(x)
      self
    end
  end

  class FunctionWriter
    extend T::Sig
    attr_reader :name
    attr_reader :type
    attr_reader :index
    attr_reader :nlocals
    attr_reader :body
    attr_accessor :export

    def initialize(name, type, index, nlocals = 0)
      @name = name
      @type = type
      @index = index
      @nlocals = nlocals
      @body = nlocals.chr
      @export = false
    end

    sig { returns(FunctionWriter) }
    def i32_add
      write_instruction(:i32_add)
      self
    end

    sig { params(value: Integer).returns(FunctionWriter) }
    def i32_const(value)
      write_instruction(:i32_const, value)
      self
    end

    def get_local(index)
      write_instruction(:get_local, index)
    end

    # rubocop: disable Naming/AccessorMethodName
    def set_local(index)
      write_instruction(:set_local, index)
    end

    def return
      write_instruction(:return)
    end

    def build
      write_instruction(:end)
      body.prepend(body.length.chr)
    end

    private

    def write_instruction(name, *args)
      body.concat(WASM.instruction_code(name))
      args.map { |a| body.concat(a) }
    end
  end
end
