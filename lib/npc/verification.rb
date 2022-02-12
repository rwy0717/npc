# typed: strict
# frozen_string_literal: true

module NPC
  # An interface for objects that are self-verifying.
  # If an attribute or operation implements this inteface,
  # then the verifier will automatically call `verify`
  # when verifying IR.
  module Verifiable
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.returns(T.nilable(Error)) }
    def verify; end
  end

  # An object that can verify some properties on an operation.
  # when an operation trait implements this interface, the verifier
  # will automatically call `verify` on all instances when
  # verifying IR.
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

    # Verify an operation, and all sub-operations.
    # Two recursive verification passes:
    # 1) verify the basic properties of the operations under the root.
    # 2) verify the cfg under the root operation.
    sig { params(operation: Operation).returns(T.nilable(Error)) }
    def call(operation)
      error = verify_operation(operation)
      return error if error
      VerifyDominance.call(operation)
    end

    # Verify the properties of a region.
    # - the entry block may not have any predecessors
    # - if the region is a graph region, it may not have more than one block
    # - each child block must be valid
    sig { params(region: Region).returns(T.nilable(Error)) }
    def verify_region(region)
      entry_block = region.first_block
      return nil if entry_block.nil?

      if entry_block.any_predecessors?
        return RegionError.new(region, "an entry block may not have any predecessor blocks")
      end

      if region.is_a?(GraphRegion)
        unless region.one_block?
          return RegionError.new(region, "a graph region may not have more than one block")
        end
      end

      block = T.let(entry_block, T.nilable(Block))
      while block
        error = verify_block(block)
        return RegionError.new(region, error) if error
        block = block.next_block
      end

      nil
    end

    # Verify the properties of a block.
    # - block must be in a region
    # - block must have a terminator, unless it's in a graph region
    # - block arguments must be valid
    # - no terminators in the interior of the block
    # - block terminator must branch to blocks in same region
    sig { params(block: Block).returns(T.nilable(Error)) }
    def verify_block(block)
      region = block.parent_region
      return BlockError.new(block, "block outside of region") unless region

      terminator = block.terminator
      if terminator.nil? && !region.is_a?(GraphRegion) && !block.parent_operation!.is_a?(NoTerminator)
        return BlockError.new(block, "block missing terminator")
      end

      block.arguments.each_with_index do |argument, index|
        if argument.index != index
          return BlockError.new(block, "argument #{argument} at position #{index} has wrong index")
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

      terminator&.block_operands&.each do |block_operand|
        if block_operand.get!.parent_region != block.parent_region
          return BlockError.new(block, "terminator #{terminator} branching outside of region")
        end
      end

      nil
    end

    # Verify the properties of an operation.
    # - The operands must be set and indexed correctly
    # - The block operands must be set and indexed correctly
    # - The block operands must be empty if the operation is not a terminator
    # - Any attributes that implement Verifiable must be valid
    # - Any inner regions must be valid
    # - All verify hooks from traits succeed
    # - The operation self-validates
    sig { params(operation: Operation).returns(T.nilable(Error)) }
    def verify_operation(operation)
      operation.operands.each do |operand|
        if operand.unset?
          return OperationError.new(operation, "unset operand #{operand}")
        end
      end

      if operation.is_a?(Terminator)
        operation.block_operands.each do |block_operand|
          if block_operand.unset?
            return OperationError.new(operation, "unset block operand #{block_operand}")
          end
        end
      elsif operation.block_operands.any?
        return OperationError.new(operation, "non-terminators may not have block-operands")
      end

      error = T.let(nil, T.nilable(Error))

      error = verify_attributes(operation)
      return OperationError.new(operation, error) if error

      operation.regions.each do |region|
        error = verify_region(region)
        return OperationError.new(operation, error) if error
      end

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

    sig { params(operation: Operation).returns(T.nilable(Error)) }
    def verify_cfg_in(operation)
      return nil if operation.regions.empty?
      VerifyDominance.call(operation)
    end
  end

  Verify = T.let(Verifier.new, Verifier)
end
