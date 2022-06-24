# typed: false
# frozen_string_literal: true

module NPC
  Cause = T.type_alias do
    T.any(NilClass, String, Error)
  end

  # An error that occured.
  #
  # Errors can track an optional "cause", which is an
  # error object that signifies the underlying error.
  # Causes can be chained together to form large traces.
  #
  # When a string is passed as the cause, it is automatically
  # converted to an ErrorMessage object.
  #
  # Errors subclass StandardError, so they can be thrown or returned.
  # In NPC, it is more idiomatic to return errors than throw.
  # Throwing is reserved for exceptions cases, and typically only a message
  # is given.
  class Error < StandardError
    extend T::Sig

    sig { params(cause: Cause).void }
    def initialize(cause = nil)
      super()
      cause = ErrorMessage.new(cause) if cause.is_a?(String)
      @cause = T.let(cause, T.nilable(Error))
    end

    sig { returns(T.nilable(Error)) }
    attr_accessor :cause

    # Follow the chain of causes to the originating error.
    # If this error has no underlying cause, returns self.
    sig { returns(Error) }
    def root_cause
      error = T.let(self, Error)
      cause = T.let(error.cause, T.nilable(Error))
      until cause.nil?
        error = cause
        cause = error.cause
      end
      error
    end

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

  #
  # Common kinds of errors
  #

  # A generic error type, containing just a string message.
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

  # An error related to an operation.
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

  # An error related to a block.
  class BlockError < Error
    extend T::Sig

    sig { params(block: Block, cause: Cause).void }
    def initialize(block, cause = nil)
      super(cause)
      @block = T.let(block, Block)
    end

    sig { returns(Block) }
    attr_accessor :block

    sig { returns(String) }
    def message
      "invalid block #{block}"
    end
  end

  # An error related to a region.
  class RegionError < Error
    extend T::Sig

    sig { params(region: Region, cause: Cause).void }
    def initialize(region, cause = nil)
      super(cause)
      @region = T.let(region, Region)
    end

    sig { returns(Region) }
    attr_accessor :region

    sig { returns(String) }
    def message
      "invalid region #{region}"
    end
  end

  # An error related to an operand.
  class OperandError < Error
    extend T::Sig

    sig { params(operand: Operand, cause: Cause).void }
    def initialize(operand, cause = nil)
      super(cause)
      @operand = T.let(operand, Operand)
    end

    sig { returns(Operand) }
    attr_accessor :operand

    sig { returns(String) }
    def message
      "invalid operand #{operand}"
    end
  end

  # An error related to a specific attribute.
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

  # An error related to an operand.
  class BlockOperandError < Error
    extend T::Sig

    sig { params(block_operand: BlockOperand, cause: Cause).void }
    def initialize(block_operand, cause = nil)
      super(cause)
      @block_operand = T.let(block_operand, Operand)
    end

    sig { returns(BlockOperand) }
    attr_accessor :block_operand

    sig { returns(String) }
    def message
      "invalid block operand #{block_operand}"
    end
  end
end
