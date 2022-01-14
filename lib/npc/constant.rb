# typed: strict
# frozen_string_literal: true

module NPC
  class NullClass; end

  # A special type used to represent nil as a compile-time constant.
  # When we fail to coerce a value to a constant, we return nil.
  # When a value would be successfully coerced to nil, we instead coerce to null.
  Null = T.let(NullClass.new, NullClass)

  # Operation trait for constant operations.
  module Constant
    extend T::Sig
    extend T::Helpers

    abstract!

    class << self
      extend T::Sig
      extend T::Helpers

      # Is this the result of a constant value?
      sig { params(value: Value).returns(T::Boolean) }
      def constant?(value)
        return false unless value.is_a?(Result)

        operation = value.operation
        return false unless operation.is_a?(Constant)

        operation.constant_result?(value)
      end

      # Try to coerce a value into a compile time constant.
      # Returns nil if the
      sig { params(value: Value).returns(T.nilable(T.untyped)) }
      def constant_value(value)
        return nil unless value.is_a?(Result)

        operation = value.defining_operation
        return nil unless operation.is_a?(Constant)

        operation.constant_result(value)
      end
    end

    # Coerce a result into a compile-time constant value.
    # returns nil if the result is nonconstant.
    sig { abstract.params(result: Result).returns(T.nilable(T.untyped)) }
    def constant_result(result); end

    # Check if a result is a compile-time constant.
    sig { overridable.params(result: Result).returns(T::Boolean) }
    def constant_result?(result)
      constant_result(result) != nil
    end
  end

  # A constant that is not represented in IR.
  module AbstractConstant
    extend T::Sig
    extend T::Helpers

    abstract!

    # The compile-time value of the constant.
    sig { abstract.returns(T.untyped) }
    def value; end

    # Materialize this abstract constant into a constant operation.
    sig { abstract.returns(Operation) }
    def materialize; end
  end

  class AbstractIntegerConstant < T::Struct
    extend T::Sig
    extend T::Helpers
    include AbstractConstant

    const :value, Integer

    sig { override.returns(Operation) }
    def materialize
      Core::IntegerConstant.new(value)
    end
  end

  class AbstractFloatConstant < T::Struct
    extend T::Sig
    extend T::Helpers
    include AbstractConstant

    const :value, Float

    sig { override.returns(Operation) }
    def materialize
      raise "cannot materialze a float (unimplemented)"
    end
  end
end
