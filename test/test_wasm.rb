# typed: false
# frozen_string_literal: true

require "wasm"
require "minitest/autorun"

def print_bytes(str)
  puts "[" + str.each_byte.to_a.join(" ") + "]"
end

describe WASM do
  describe "#magic" do
    it "should be a string of bytes" do
      assert_equal WASM.magic.class, String
    end
  end
end

class WasmTest < Minitest::Test
  def test_empty_module
    m = WASM::ModuleWriter.new
    t = m.type([:i32, :i32], [:i32])
    f = m.function("sum", t)
    f.export = true

    f.get_local(0)
    f.get_local(1)
    f.i32_add
    f.return

    m.start(f)

    data = m.build
    p(data.unpack("H*"))
    p(data)

    File.open("test.wasm", "w") { |file| file.write(data) }
  end
end
