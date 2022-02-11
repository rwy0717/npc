# typed: strict
# frozen_string_literal: true

module NPC
  Cause = T.type_alias do
    T.any(NilClass, String, Error)
  end

  class Error < RuntimeError
    extend T::Sig

    sig { params(cause: Cause).void }
    def initialize(cause = nil)
      if cause.is_a?(String)
        cause = ErrorMessage.new(cause)
      end
      @cause = T.let(cause, T.nilable(Error))
    end

    sig { returns(T.nilable(Error)) }
    attr_accessor :cause

    sig { returns(String) }
    def to_s
      msg = "error: #{message}".dup
      iter = T.let(cause, T.nilable(Error))
      while iter
        msg << "\n    -> #{iter.message}"
        iter = iter.cause
      end
      msg << "\n"
    end
  end

  class ErrorMessage < Error
    extend T::Sig

    sig { params(message: String, cause: Cause).void }
    def initialize(message, cause = nil)
      super(cause)
      @message = T.let(message, String)
    end

    sig { returns(String) }
    attr_accessor :message
  end

  class OperationError < Error
    extend T::Sig

    sig { params(operation: Operation, cause: Cause).void }
    def initialize(operation, cause = nil)
      super(cause)
      @operation = T.let(operation, Operation)
    end

    sig { returns(Operation) }
    attr_accessor :operation

    sig { returns(String) }
    def message
      "invalid operation #{operation}"
    end
  end

  class AttributeError < Error
    extend T::Sig

    sig { params(key: Symbol, val: T.untyped, cause: Cause).void }
    def initialize(key, val, cause = nil)
      super(cause)
      @key = T.let(key, Symbol)
      @val = T.let(val, T.untyped)
    end

    sig { returns(Symbol) }
    attr_accessor :key

    sig { returns(T.untyped) }
    attr_accessor :val

    sig { returns(String) }
    def message
      "invalid attribute {#{key} => #{val}}"
    end
  end
end
