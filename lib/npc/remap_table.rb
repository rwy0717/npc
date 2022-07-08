# typed: strict
# frozen_string_literals: true
# frozen_string_literal: true

module NPC
  # A table that maps between an original IR object and it's replacement.
  # A helper for cloning IR objects.
  class RemapTable
    extend T::Sig
    extend T::Helpers

    sig do
      params(
        block_table: T::Hash[Block, Block],
        value_table: T::Hash[Value, Value],
      ).void
    end
    def initialize(block_table: {}, value_table: {})
      @block_table = T.let(block_table, T::Hash[Block, Block])
      @value_table = T.let(value_table, T::Hash[Value, Value])
    end

    sig { returns(T::Hash[Block, Block]) }
    attr_reader :block_table

    sig { returns(T::Hash[Value, Value]) }
    attr_reader :value_table

    sig { params(a: Block, b: Block).void }
    def remap_block!(a, b)
      @block_table[a] = b
    end

    sig { params(a: Value, b: Value).void }
    def remap_value!(a, b)
      @value_table[a] = b
    end

    sig { params(block: T.nilable(Block)).returns(T.nilable(Block)) }
    def get_block(block)
      if block
        @block_table[block] || block
      end
    end

    sig { params(value: T.nilable(Value)).returns(T.nilable(Value)) }
    def get_value(value)
      if value
        @value_table[value] || value
      end
    end

    sig { params(value: T.nilable(Value)).returns(T::Boolean) }
    def include_value?(value)
      value ? @value_table.include?(value) : false
    end

    sig { params(block: T.nilable(Block)).returns(T::Boolean) }
    def include_block?(block)
      block ? @block_table.include?(block) : false
    end
  end
end
