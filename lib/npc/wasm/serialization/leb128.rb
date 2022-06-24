# typed: true
# frozen_string_literal: true

module NPC
  module ULEB128
    class << self
      extend T::Sig

      sig { params(x: Integer, minimum_bytes: Integer).returns(String) }
      def encode(x, minimum_bytes: 0)
        bytes = String.new
        n = 0
        loop do
          byte = x & 0x7F
          x >>= 7
          n += 1
          if x == 0 && minimum_bytes <= n
            bytes.concat(byte)
            break
          end
          bytes.concat(byte | 0x80)
        end
        bytes
      end

      # sig { params(x: Integer, o: String, minimum_bytes: Integer).returns(String) }
      # def encode_at(x, o, at = 0, minimum_bytes: 0)
      #   raise "not implemented"
      # end

      sig { params(string: String).returns(Integer) }
      def decode(string)
        decode_stream(string.each_byte)
      end

      sig { params(stream: Enumerable).returns(Integer) }
      def decode_stream(stream)
        value = 0
        index = 0
        stream.each do |byte|
          value += (byte & 0x7F) << (index * 7)
          if byte & 0x80 == 0
            break
          end

          index += 1
        end
        value
      end
    end
  end

  module SLEB128
    extend T::Sig
    include Kernel

    sig { params(x: Integer).returns(String) }
    def encode(x)
      bytes = String.new
      loop do
        byte = x & 0x7F
        x >>= 7
        if (x == 0 && (byte & 0x40 == 0)) || (x == -1 && (byte & 0x40 != 0))
          bytes.concat(byte)
          break
        else
          bytes.concat(byte | 0x80)
        end
      end
      bytes
    end
    module_function :encode

    sig { params(string: String).returns(Integer) }
    def decode(string)
      decode_stream(string.each_byte)
    end
    module_function :decode

    sig { params(stream: Enumerable).returns(Integer) }
    def decode_stream(stream)
      value = 0
      index = 0
      stream.each do |byte|
        value += (byte & 0x7F) << (index * 7)
        index += 1
        next unless byte & 0x80 == 0

        if byte & 0x40 != 0
          value |= -(1 << (index * 7))
        end
        break
      end
      value
    end
    module_function :decode_stream
  end
end
