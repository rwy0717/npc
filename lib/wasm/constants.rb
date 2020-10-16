# typed: true
# frozen_string_literal: true

module WASM
  extend T::Sig

  MAGIC = T.let("\x00\x61\x73\x6d", String)
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
    unreachable: "\x00",
    nop: "\x01",
    block: "\x02",
    loop: "\x03",
    if: "\x04",
    else: "\x05",
    end: "\x0b",
    br: "\x0c",
    br_if: "\x0d",
    br_table: "\x0e",
    return: "\x0f",
    call: "\x10",
    call_indirect: "\x11",

    # Parametric Instructions
    drop: "\x1a",
    select: "\x1b",

    # Variable Instructions

    local_get: "\x20",
    local_set: "\x21",
    local_tee: "\x22",
    global_get: "\x23",
    global_set: "\x24",

    # Memory Instructions

    i32_load: "\x28",
    i64_load: "\x29",
    f32_load: "\x2a",
    f64_load: "\x2b",
    i32_load8_s: "\x2c",
    i32_load8_u: "\x2d",
    i32_load16_s: "\x2e",
    i32_load16_u: "\x2f",
    i64_load8_s: "\x30",
    i64_load8_u: "\x31",
    i64_load16_s: "\x32",
    i64_load16_u: "\x33",
    i64_load32_s: "\x34",
    i64_load32_u: "\x35",

    i32_store: "\x36",
    i64_store: "\x37",
    f32_store: "\x38",
    f64_store: "\x39",
    i32_store8: "\x3a",
    i32_store16: "\x3b",
    i64_store8: "\x3c",
    i64_store16: "\x3d",
    i64_store32: "\x3e",

    current_memory: "\x3f",
    grow_memory: "\x40",

    # Numeric Instructions

    i32_const: "\x41",
    i64_const: "\x42",
    f32_const: "\x43",
    f64_const: "\x44",

    i32_eqz: "\x45",
    i32_eq: "\x46",
    i32_ne: "\x47",
    i32_lt_s: "\x48",
    i32_lt_u: "\x49",
    i32_gt_s: "\x4a",
    i32_gt_u: "\x4b",
    i32_le_s: "\x4c",
    i32_le_u: "\x4d",
    i32_ge_s: "\x4e",
    i32_ge_u: "\x4f",

    i64_eqz: "\x50",
    i64_eq: "\x51",
    i64_ne: "\x52",
    i64_lt_s: "\x53",
    i64_lt_u: "\x54",
    i64_gt_s: "\x55",
    i64_gt_u: "\x56",
    i64_le_s: "\x57",
    i64_le_u: "\x58",
    i64_ge_s: "\x59",
    i64_ge_u: "\x5a",

    f32_eq: "\x5b",
    f32_ne: "\x5c",
    f32_lt: "\x5d",
    f32_gt: "\x5e",
    f32_le: "\x5f",
    f32_ge: "\x60",

    f64_eq: "\x61",
    f64_ne: "\x62",
    f64_lt: "\x63",
    f64_gt: "\x64",
    f64_le: "\x65",
    f64_ge: "\x66",

    i32_clz: "\x67",
    i32_ctz: "\x68",
    i32_popcnt: "\x69",
    i32_add: "\x6a",
    i32_sub: "\x6b",
    i32_mul: "\x6c",
    i32_div_s: "\x6d",
    i32_div_u: "\x6e",
    i32_rem_s: "\x6f",
    i32_rem_u: "\x70",
    i32_and: "\x71",
    i32_or: "\x72",
    i32_xor: "\x73",
    i32_shl: "\x74",
    i32_shr_s: "\x75",
    i32_shr_u: "\x76",
    i32_rotl: "\x77",
    i32_rotr: "\x78",

    i64_clz: "\x79",
    i64_ctz: "\x7a",
    i64_popcnt: "\x7b",
    i64_add: "\x7c",
    i64_sub: "\x7d",
    i64_mul: "\x7e",
    i64_div_s: "\x7f",
    i64_div_u: "\x80",
    i64_rem_s: "\x81",
    i64_rem_u: "\x82",
    i64_and: "\x83",
    i64_or: "\x84",
    i64_xor: "\x85",
    i64_shl: "\x86",
    i64_shr_s: "\x87",
    i64_shr_u: "\x88",
    i64_rotl: "\x89",
    i64_rotr: "\x8a",

    f32_abs: "\x8b",
    f32_neg: "\x8c",
    f32_ceil: "\x8d",
    f32_floor: "\x8e",
    f32_trunc: "\x8f",
    f32_nearest: "\x90",
    f32_sqrt: "\x91",
    f32_add: "\x92",
    f32_sub: "\x93",
    f32_mul: "\x94",
    f32_div: "\x95",
    f32_min: "\x96",
    f32_max: "\x97",

    f32_copysign: "\x98",
    f64_abs: "\x99",
    f64_neg: "\x9a",
    f64_ceil: "\x9b",
    f64_floor: "\x9c",
    f64_trunc: "\x9d",
    f64_nearest: "\x9e",
    f64_sqrt: "\x9f",
    f64_add: "\xa0",
    f64_sub: "\xa1",
    f64_mul: "\xa2",
    f64_div: "\xa3",
    f64_min: "\xa4",
    f64_max: "\xa5",
    f64_copysign: "\xa6",

    ## conversions

    i32_wrap_i64: "\xa7",
    i32_trunc_s_f32: "\xa8",
    i32_trunc_u_f32: "\xa9",
    i32_trunc_s_f64: "\xaa",
    i32_trunc_u_f64: "\xab",
    i64_extend_s_i32: "\xac",
    i64_extend_u_i32: "\xad",
    i64_trunc_s_f32: "\xae",
    i64_trunc_u_f32: "\xaf",
    i64_trunc_s_f64: "\xb0",
    i64_trunc_u_f64: "\xb1",
    f32_convert_s_i32: "\xb2",
    f32_convert_u_i32: "\xb3",
    f32_convert_s_i64: "\xb4",
    f32_convert_u_i64: "\xb5",
    f32_demote_f64: "\xb6",
    f64_convert_s_i32: "\xb7",
    f64_convert_u_i32: "\xb8",
    f64_convert_s_i64: "\xb9",
    f64_convert_u_i64: "\xba",
    f64_promote_f32: "\xbb",

    ## reinterpretations

    i32_reinterpret_f32: "\xbc",
    i64_reinterpret_f64: "\xbd",
    f32_reinterpret_i32: "\xbe",
    f64_reinterpret_i64: "\xbf",
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
end
