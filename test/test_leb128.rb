# typed: false
# frozen_string_literal: true

require "leb128"
require "minitest/autorun"

def print_bytes(str)
  puts "[" + str.each_byte.to_a.join(" ") + "]"
end

describe ULEB128 do
  describe "#encode" do
    it "should_encode_correctly" do
      assert_equal "\x00".b, ULEB128.encode(0)
      assert_equal "\x01".b, ULEB128.encode(1)
      assert_equal "\x7F".b, ULEB128.encode(0x7F)
      assert_equal "\x80\x01".b, ULEB128.encode(0x80)
      assert_equal "\xFF\x01".b, ULEB128.encode(0xFF)
      assert_equal "\xA3\xE0\xD4\xB9\xBF\x86\x02".b, ULEB128.encode(9019283812387)
    end
  end
  describe "#decode" do
    it "should_decode_correctly" do
      assert_equal 0, ULEB128.decode("\x00")
      assert_equal 1, ULEB128.decode("\x01")
      assert_equal 0x7F, ULEB128.decode("\x7F")
      assert_equal 0x80, ULEB128.decode("\x80\x01")
      assert_equal 0xFF, ULEB128.decode("\xFF\x01")
      assert_equal 9019283812387, ULEB128.decode("\xA3\xE0\xD4\xB9\xBF\x86\x02")
    end
  end

  it "should_round_trip" do
    [0, 1, 0xFFFFFFFE, 0xFFFFFFFF].each do |x|
      assert_equal x, ULEB128.decode(ULEB128.encode(x))
    end
  end
end

describe SLEB128 do
  describe "#encode" do
    it "should_encode_correctly" do
      assert_equal "\x00".b, SLEB128.encode(0)
      assert_equal "\x01".b, SLEB128.encode(1)
      assert_equal "\xFF\x00".b, SLEB128.encode(0x7F)
      assert_equal "\x80\x01".b, SLEB128.encode(0x80)
      assert_equal "\xFF\x01".b, SLEB128.encode(0xFF)
      assert_equal "\x7F".b, SLEB128.encode(-1)
      assert_equal "\xDD\x9F\xAB\xC6\xC0\xF9\x7D".b, SLEB128.encode(-9019283812387)
    end
    describe "#decode" do
      it "should_decode_correctly" do
        assert_equal 0, SLEB128.decode("\x00")
        assert_equal 1, SLEB128.decode("\x01\x00")
        assert_equal(-1, SLEB128.decode("\x7F"))
        assert_equal 0x80, SLEB128.decode("\x80\x01")
        assert_equal 0xFF, SLEB128.decode("\xFF\x01")
        assert_equal 9019283812387, SLEB128.decode("\xA3\xE0\xD4\xB9\xBF\x86\x02")
        assert_equal(-1, SLEB128.decode("\x7F"))
        assert_equal(-9019283812387, SLEB128.decode("\xDD\x9F\xAB\xC6\xC0\xF9\x7D"))
      end
    end

    it "should_round_trip" do
      [-0x7FFFFFFF, -0xFFFFFFFE, -2, -1, -0, 0, 1, 2, 0xFFFFFFFE, 0xFFFFFFFF].each do |x|
        assert_equal x, SLEB128.decode(SLEB128.encode(x))
      end
    end
  end
end
