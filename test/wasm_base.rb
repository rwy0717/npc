# typed: strict
# frozen_string_literal: true

require_relative("test")

# require "wasm"
# require "minitest/autorun"

# def print_bytes(str)
#   puts "[" + str.each_byte.to_a.join(" ") + "]"
# end

# describe WASM do
#   describe "#magic" do
#     it "should be a string of bytes" do
#       assert_equal WASM.magic.class, String
#     end
#   end

#   describe "#version" do
#     it "should be a string of bytes" do
#       assert_equal WASM.version.class, String
#     end
#   end
# end

# describe WASM::FuncType do
#   include WASM

#   describe "#eql" do
#     it "should be equal to itself" do
#       assert_equal func_type([], []), func_type([], [])
#       assert_equal func_type([:i32], []), func_type([:i32], [])
#       assert_equal func_type([:i32], []), func_type(:i32)
#     end

#     it "should not be equal to different types" do
#       refute_equal func_type([], []), func_type([], [:i32])
#       refute_equal func_type([:i32], []), func_type([], [:i32])
#       refute_equal func_type([], [:i32]), func_type([:i32], [])
#     end

#     it "should work as a key in a hashtable" do
#       x = {}
#       x[func_type([:i32], [:i32])] = 1234
#       x[func_type([:i64], [:i64])] = 5678

#       assert_equal 1234, x[func_type([:i32], [:i32])]
#       assert_equal 5678, x[func_type([:i64], [:i64])]
#     end
#   end
# end

# describe WASM::FuncTypeTable do
#   describe "#intern" do
#     it "should intern types" do
#       table = WASM::FuncTypeTable.new
#       a = table.intern(WASM::FuncType.new([:i32, :i32], :i32))
#       b = table.intern(WASM::FuncType.new([:i32, :i32], :i32))
#       assert_equal a, b
#     end
#   end
# end

# describe WASM::ModuleWriter do
#   it "should generate an empty module" do
#     File.open("empty.wasm", "w") do |_file|
#       p WASM::ModuleWriter.new.build
#     end
#   end

#   it "should intern func types correctly" do
#     m = WASM::ModuleWriter.new
#     assert_equal m.type([:i32], :i32), m.type([:i32], :i32)
#   end
# end

# class WasmTest < Minitest::Test
#   extend T::Sig

#   sig { void }
#   def test_empty_module
#     m = WASM::ModuleWriter.new

#     m.func(m.type([:i32, :i32], :i32))
#       .export("add")
#       .local(:i64, 1)
#       .local_get(0)
#       .local_get(1)
#       .i32_add
#       .i32_const(42)
#       .i32_add
#       .return

#     m.func(m.type([:i32, :i32], :i32))
#       .export("sub")
#       .export("sub_by_another_name_wouldst_decrement_as_sweet")
#       .local(:i64, 2)
#       .local_get(0)
#       .local_get(1)
#       .i32_sub
#       .return

#     data = m.build
#     p(data.unpack("H*"))
#     p(data)

#     File.open("test.wasm", "w") { |file| file.write(data) }
#   end
# end
