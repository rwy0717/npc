# typed: strict
# frozen_string_literal: true

module NPC
  # An object that is self-verifying.
  module Verifiable
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.returns(T.nilable(Error)) }
    def verify; end
  end

  # An object that can verify some properties on an operation.
  module OperationVerifier
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.params(operation: Operation).returns(T.nilable(Error)) }
    def verify(operation); end
  end

  # The central IR verification engine.
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

      error = T.let(nil, T.nilable(Error))

      error = verify_attributes(operation)
      return OperationError.new(operation, error) if error

      operation.regions.each do |region|
        error = verify_region(region)
        return OperationError.new(operation, error) if error
      end

      verify_cfg_in(operation)
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
      entry_block = region.first_block
      return nil if entry_block.nil?

      if entry_block.any_predecessors?
        return RegionError.new(region, "an entry block may not have any predecessor blocks")
      end

      block = T.let(entry_block, T.nilable(Block))
      while block
        error = verify_block(block)
        return RegionError.new(region, error) if error
        block = block.next_block
      end

      nil
    end

    sig { params(block: Block).returns(T.nilable(Error)) }
    def verify_block(block)
      region = block.parent_region
      return BlockError.new(block, "block outside of region") unless region

      terminator = block.terminator
      if terminator && !region.is_a?(GraphRegion)
        return BlockError.new(block, "block missing terminator")
      end

      block.arguments.each_with_index do |argument, index|
        if argument.index != index
          return BlockError.new(block, "argument #{argument} has wrong index")
        end

        if argument.type.nil?
          return BlockError.new(block, "argument #{argument} missing type")
        end
      end

      block.operations.each do |operation|
        if operation.is_a?(Terminator) && operation != terminator
          return BlockError.new(block, "terminator #{operation} in middle of block")
        end
      end

      nil
    end

    sig { params(operation: Operation).returns(T.nilable(Error)) }
    def verify_cfg_in(operation)
      return nil if operation.regions.empty?
      VerifyDominance.call(operation)
    end
  end

  Verify = T.let(Verifier.new, Verifier)
end
