# typed: strict
# frozen_string_literal: true

module NPC
  module Verifiable
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.returns(T.nilable(Error)) }
    def verify; end
  end

  module OperationVerifier
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.params(operation: Operation).returns(T.nilable(Error)) }
    def verify(operation); end
  end

  class Verifier
    extend T::Sig

    sig { params(operation: Operation).returns(T.nilable(Error)) }
    def call(operation)
      operation.operands.each do |operand|
        if operand.unset?
          return OperationError.new(operation, "unset operand #{operand}")
        end
      end

      operation.block_operands.each do |block_operand|
        if block_operand.unset?
          return OperationError.new(operation, "unset block operand #{block_operand}")
        end
      end

      operation.regions.each do |region|
        error = verify_region(region)
        return OperationError.new(operation, error) if error
      end

      nil
    end

    sig { params(operation: Operation).returns(T.nilable(Error)) }
    def verify_operation(operation)
      nil
    end

    sig { params(operation: Operation).returns(T.nilable(Error)) }
    def verify_attributes(operation)
      operation.attributes.each do |key, val|
        if val.is_a?(Verifiable)
          error = val.verify
          return AttributeError.new(key, val, error) if error
        end
      end
      nil
    end

    sig { params(region: Region).returns(T.nilable(Error)) }
    def verify_region(region)
      nil
    end
  end

  Verify = T.let(Verifier.new, Verifier)
end
