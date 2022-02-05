# typed: strict
# frozen_string_literal: true

module NPC
  # A special operand type that refers to a block.
  class BlockOperand
    extend T::Sig
    extend T::Helpers

    sig do
      params(
        owning_operation: Operation,
        index: Integer,
        target: T.nilable(Block),
      ).void
    end
    def initialize(owning_operation, index, target = nil)
      @owning_operation = T.let(owning_operation, Operation)
      @index = T.let(index, Integer)
      @target = T.let(nil, T.nilable(Block))
      @prev_use  = T.let(nil, T.nilable(BlockOperand))
      @next_use  = T.let(nil, T.nilable(BlockOperand))
      set!(target) if target
    end

    # The operation that this block-operand belongs to.
    sig { returns(Operation) }
    attr_reader :owning_operation

    # This block-operand's index in the operation's block-operand array.
    sig { returns(Integer) }
    attr_reader :index

    # The previous block-operand in the target block's list of uses.
    sig { returns(T.nilable(BlockOperand)) }
    attr_accessor :prev_use

    # The next block-operand in the target block's list of uses.
    sig { returns(T.nilable(BlockOperand)) }
    attr_accessor :next_use

    # This block-operand's target block, if set. Otherwise, nil.
    sig { returns(T.nilable(Block)) }
    def get
      @target
    end

    # This block-operand's target block. Target must be set.
    sig { returns(Block) }
    def get!
      T.must(@target)
    end

    # True if this block-operand's target is set.
    sig { returns(T::Boolean) }
    def set?
      @target != nil
    end

    # True if this block-operand's target is not set.
    sig { returns(T::Boolean) }
    def unset?
      @target.nil?
    end

    sig { params(x: Block).returns(T::Boolean) }
    def is?(x)
      @target.equal?(x)
    end

    # Set the target block of this block-operand. Target must not be already set.
    sig { params(target: Block).void }
    def set!(target)
      raise "block operand target already set" unless @target.nil?

      @target = target
      @next_use = @target.first_use
      @next_use.prev_use = self if @next_use
      @target.first_use = self
    end

    ## Clear this block-operand. This block-operand must be targeting a block.
    sig { void }
    def unset!
      raise "block operand already unset" if @target.nil?

      if @target.first_use == self
        @target.first_use = @next_use
      end

      @prev_use.next_use = @next_use if @prev_use
      @next_use.prev_use = @prev_use if @next_use

      @target = nil
      @prev_use = nil
      @next_use = nil
    end

    # Reset this block-operand, to target a new block.
    sig { params(target: T.nilable(Block)).void }
    def reset!(target)
      unset! if set?
      set!(target) if target
    end

    # Clear this block-operand, if it is set.
    sig { void }
    def drop!
      unset! if set?
    end

    # Copy this block-operand into another operation.
    sig { params(operation: Operation).returns(BlockOperand) }
    def copy_into(operation)
      operation.new_block_operand(@target)
    end
  end
end
