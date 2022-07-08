# typed: strict
# frozen_string_literal: true

module NPC
  # A special operand type that refers to a block.
  # These are used to model control flow,
  # so only {Terminator} operations can have {BlockOperand}s.
  # A block operand is assumed to be a potential jump target.
  class BlockOperand
    extend T::Sig
    extend T::Helpers

    sig do
      params(
        parent_operation: T.nilable(Operation),
        target:           T.nilable(Block),
      ).void
    end
    def initialize(parent_operation = nil, target = nil)
      @parent_operation = T.let(parent_operation, T.nilable(Operation))
      @target           = T.let(nil, T.nilable(Block))
      @prev_use  = T.let(nil, T.nilable(BlockOperand))
      @next_use  = T.let(nil, T.nilable(BlockOperand))
      set!(target) if target
    end

    # The operation that this block-operand belongs to.
    sig { returns(T.nilable(Operation)) }
    attr_accessor :parent_operation

    sig { returns(Operation) }
    def parent_operation!
      T.must(@parent_operation)
    end

    # This block-operand's index in the operation's block-operand array.
    sig { returns(T.nilable(Integer)) }
    def index
      @parent_operation&.block_operands&.find_index(self)
    end

    sig { returns(Integer) }
    def index!
      T.must(index)
    end

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
