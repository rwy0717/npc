# typed: true
# frozen_string_literal: true

require("wasm/module_writer")

module WASM
  sig do
    params(
      args: T.any(Symbol, T::Array[Symbol]),
      rets: T.any(Symbol, T::Array[Symbol]),
    ).returns(FuncType)
  end
  def func_type(args, rets = [])
    FuncType.new(args, rets).freeze
  end
  module_function :func_type

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
      @args = mung_type_array(args)
      @rets = mung_type_array(rets)
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
    def mung_type_array(x)
      check_type_array(coerce_type_array(x))
    end

    sig { params(x: T.any(Symbol, T::Array[Symbol])).returns(T::Array[Symbol]) }
    def coerce_type_array(x)
      if x.is_a?(Array)
        x.frozen? ? x : x.dup.freeze
      else
        [x].freeze
      end
    end

    sig { params(x: T::Array[Symbol]).returns(T::Array[Symbol]) }
    def check_type_array(x)
      x.each do |t|
        check_type(t)
      end
    end

    sig { params(x: Symbol).returns(Symbol) }
    def check_type(x)
      raise ArgumentError, "Expected a valid type symbol, got #{x}" unless TYPE_CODES[x]
      x
    end
  end
end
