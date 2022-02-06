# typed: strict
# frozen_string_literal: true

module NPC
  class Dominance
    class BlockInfo
      extend T::Sig

      sig { params(block: Block) }
      def initialize(block)
        @block = block
        @index_table = T.let({}, T::Hash[Operation, Index])

        block.operations.each_with_index do |operation, index|
          @index_table[operation] = index
        end
      end

      sig { params(a: Operation, b: Operation).returns(T::Boolean) }
      def dominates(a, b)
        raise "operation not in block" unless a.parent_block == @block && b.parent_block == @block
        @index_table.fetch(a) > index_table.fetch(b)
      end

      sig { params(a: Operation, b: Operation).returns(T::Boolean) }
      def properly_dominates(a, b)
        a != b && dominates(a, b)
      end
    end

    class RegionInfo
      extend T::Sig

      sig { params(region: Region) }
      def initialize(region)
        @region = region
        @block_info_table = T.let({}, T::Hash[Block, BlockInfo])
      end

      sig { params(block: Block).returns(BlockInfo) }
      def block_info(block)
        raise "block not in region" if block.parent_region != @region
        @block_info_table[block] ||= BlockInfo.new(block)
      end

      sig { params(a: Operation, b: Operation).returns(T::Boolean) }
      def dominates(a, b)
        block_a = a.parent_block!
        block_b = b.parent_block!
        if block_a == block_b
          return block_info(blk).dominates(a, b)
        end
        block_dominates(block_a, block_b)
      end

      sig { params(a: Block, b: Block).returns(T::Boolean) }
      def block_dominates(a, b)
        true
      end

      sig { params(a: Block, b: Block).returns(T::Boolean) }
      def block_dominates(a, b)
        get_dom_tree.block_dominates(a, b)
      end
    end

    extend T::Sig

    sig { void }
    def initialize
      @region_info_table = T.let({}, T::Hash[Region, RegionInfo])
    end

    sig { returns(RegionInfo) }
    def region_info(region)
      @region_info_table[region] ||= RegionInfo.new(region)
    end

    # Get the highest ancestor of operation that is still a descendent of region.
    sig { params(operation: Operation, target: Region).returns(T.nilable(Operation)) }
    def ancestor_in_region(operation, target)
      loop do
        region = operation.parent_region
        return nil if region.nil?
        return operation if region == target
        operation = region.parent_operation!
      end
    end

    sig { params(block: Block, target: Region).returns(T.nilable(Block)) }
    def block_ancestor_in_region(block, target)
      loop do
        region = block.parent_region!
        return block if region == target
        block = region.parent_block
        return nil if block.nil?
      end
    end

    # Test if operation a is "before" operation b.
    # If determining non-strict domination, then:
    #   a dominates itself and any descendent (inner) operations.
    # If determining strict domination, then:
    #   a does not dominate itself, or any descendent operations.
    # Determines non-strict domination by default.
    sig { params(a: Operation, b: Operation, strict: T::Boolean).returns(T::Boolean) }
    def dominates(a, b, strict: false)
      block_a = a.parent_block!
      region_a = block_a.parent_region!
      b = ancestor_in_region(b, region_a)
      return false if b.nil?
      return !strict if a == b
      region_info(region_a).dominates(a, b)
    end

    # Test if operation a is "before" operation b.
    # a dominates any descendent (inner) operations, but not itself.
    # This is in contrast to:
    # - strict domination, where a would not dominate inner operations.
    # - non-strict domination, where a is considered to dominate itself.
    sig { params(a: Operation, b: Operation).returns(T::Boolean) }
    def properly_dominates(a, b)
      return false if a == b
      dominates(a, b, strict: false)
    end

    # Does the block a come "before" block b?
    # If determining non-strict domination, then:
    #   a dominates itself and any descendent (inner) blocks.
    # If determining strict domination, then:
    #   a does not dominate itself, or any descendent operations.
    # Determines non-strict domination by default.
    sig { params(a: Block, b: Block).returns(T::Boolean) }
    def block_dominates(a, b, strict: false)
      region_a = a.parent_region!
      b = block_ancestor_in_region(b, region_a)
      return false if b.nil?
      return !strict if a == b
      region_info(region_a).block_dominates(a, b)
    end

    # Is the value defined before an operation, such that the value can be used
    # as an operand to the operation.
    sig { params(value: Value, operation: Operation).returns(T::Boolean) }
    def value_dominates(value, operation)
      case value
      when Argument
        value.owning_block.ancestor_of(operation)
      when Result
        dominates(value.owning_operation, operation, strict: true)
      else
        raise "Unknown class #{value.class.name}"
      end
    end
  end
end
