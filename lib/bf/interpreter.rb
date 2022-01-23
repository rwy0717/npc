# typed: strict
# frozen_string_literal: true

module BF
  class Interpreter < T::Struct
    class << self
      extend T::Sig
      sig do
        params(
          prog: String,
          istr: T::Array[Integer],
        ).returns(T::Array[Integer])
      end
      def call(prog, istr = [])
        interpreter = new(prog: prog, istr: istr)
        interpreter.call
        interpreter.ostr
      end

      sig do
        params(
          prog: String,
          istr: String,
        ).returns(String)
      end
      def call_str(prog, istr = "")
        ary_to_str(
          call(prog, str_to_ary(istr))
        )
      end

      sig { params(ary: T::Array[Integer]).returns(String) }
      def ary_to_str(ary)
        ary.pack("c*")
      end

      sig { params(str: String).returns(T::Array[Integer]) }
      def str_to_ary(str)
        str.bytes
      end
    end

    extend T::Sig

    const :prog, String
    const :istr, T::Array[Integer]

    prop :data, T::Array[Integer], factory: -> { [] }
    prop :ostr, T::Array[Integer], factory: -> { [] }

    prop :prog_index, Integer, default: 0
    prop :data_index, Integer, default: 0
    prop :istr_index, Integer, default: 0

    sig { params(index: Integer).returns(Integer) }
    def get_data_at(index)
      data[index] || 0
    end

    sig { params(index: Integer, value: Integer).void }
    def set_data_at(index, value)
      data[index] = value
    end

    sig { returns(Integer) }
    def get_data
      get_data_at(data_index)
    end

    sig { params(value: Integer).void }
    def set_data(value)
      set_data_at(data_index, value)
    end

    sig { void }
    def move_left
      @data_index -= 1
    end

    sig { void }
    def move_right
      @data_index += 1
    end

    sig { void }
    def increment
      set_data(get_data + 1)
    end

    sig { void }
    def decrement
      set_data(get_data - 1)
    end

    sig { void }
    def output
      ostr << get_data
    end

    sig { void }
    def input
      set_data(@istr[@istr_index] || 0)
      @istr_index += 1
    end

    sig { void }
    def jump_forward_if_zero
      return unless get_data == 0

      depth = 1
      until depth == 0
        @prog_index += 1
        if prog[prog_index] == "]"
          depth -= 1
        elsif prog[prog_index] == "["
          depth += 1
        end
      end
    end

    sig { void }
    def jump_backward_if_nonzero
      return unless get_data != 0

      depth = 1
      until depth == 0
        @prog_index -= 1
        if prog[prog_index] == "]"
          depth += 1
        elsif prog[prog_index] == "["
          depth -= 1
        end
      end
    end

    sig { void }
    def call
      while prog_index < prog.length
        case prog[prog_index]
        when ">"
          move_right
        when "<"
          move_left
        when "+"
          increment
        when "-"
          decrement
        when "."
          output
        when ","
          input
        when "["
          jump_forward_if_zero
        when "]"
          jump_backward_if_nonzero
        end
        @prog_index += 1
      end
    end
  end
end
