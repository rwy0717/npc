# typed: strict
# frozen_string_literal: true

module NPC
  # Information about when a block dominates another in a given region
  class DominatorTree
    class Node < T::Struct
      extend T::Sig

      prop :block, Block
      prop :index, Integer
      # the immediate dominator. Also called an idom.
      prop :parent, T.nilable(Node)

      sig { returns(String) }
      def inspect
        "<Node:#{object_id}: block=#{block.object_id}, index=#{index}, parent=#{parent.object_id}>"
      end
    end

    extend T::Sig

    sig { params(region: Region).void }
    def initialize(region)
      @table = T.let({}, T::Hash[Block, Node])

      first_block = region.first_block
      return unless first_block

      # create a list of all the tree nodes

      nodes = []

      PostOrder.new(first_block).each_with_index do |block, index|
        node = Node.new(block: block, index: index)
        nodes << node
        @table[block] = node
      end

      # The entry node dominates itself, has no proper dominators.
      first_node = nodes.pop
      first_node.parent = first_node

      changed = T.let(true, T::Boolean)
      while changed
        changed = false

        nodes.reverse.each do |node|
          block    = node.block
          new_idom = T.let(nil, T.nilable(Node))

          block.predecessors.each do |pred|
            pred_node = @table.fetch(pred)
            if pred_node.parent
              new_idom = intersect(new_idom, pred_node)
            end
          end

          if node.parent != new_idom
            node.parent = new_idom
            changed = true
          end
        end
      end
    end

    sig { returns(T::Hash[Block, Node]) }
    attr_reader :table

    sig { params(block: Block).returns(Node) }
    def node(block)
      table.fetch(block)
    end

    sig { params(a: Block, b: Block).returns(T::Boolean) }
    def dominates(a, b)
      node_a = @table.fetch(a)
      node_b = @table.fetch(b)
      loop do
        return true if node_a == node_b
        parent = node_b.parent
        # The entry node is dominated by itself, so break if
        # we get that far.
        break if node_b == parent
        node_b = T.must(parent)
      end
      false
    end

    # Find the nearest common ancestor of two nodes in the dominance tree.
    # This is their common dominator.
    sig { params(a: T.nilable(Node), b: Node).returns(Node) }
    def intersect(a, b)
      return b if a.nil?

      until a == b
        a = T.must(a.parent) while a.index < b.index
        b = T.must(b.parent) while a.index > b.index
      end
      a
    end
  end

  class Dominance
    # Dominance information about the operations in a block.
    # Essentially, assigns indexes to the operations in a block.
    # If two operations are in the same block, the operation with
    # the lower index occurs earlier in the block, and thus dominates
    # the later operation.
    class BlockInfo
      extend T::Sig

      sig { params(block: Block).void }
      def initialize(block)
        @block = block
        @index_table = T.let({}, T::Hash[Operation, Integer])

        block.operations.each_with_index do |operation, index|
          @index_table[operation] = index
        end
      end

      sig { params(a: Operation, b: Operation).returns(T::Boolean) }
      def dominates(a, b)
        raise "operation not in block" if
          a.parent_block != @block || b.parent_block != @block

        @index_table.fetch(a) < @index_table.fetch(b)
      end

      sig { params(a: Operation, b: Operation).returns(T::Boolean) }
      def properly_dominates(a, b)
        a != b && dominates(a, b)
      end
    end

    # Dominance information for blocks in a region.
    # If two operations are in different blocks,
    # then we can look at the dominance of their blocks
    # to determine dominance of the two operations.
    # Dominance between blocks is represented as a tree,
    # where each node points back at it's dominator.
    #
    # RegionInfo is constructed lazily.
    #
    # see: DominatorTree
    class RegionInfo
      extend T::Sig

      sig { params(region: Region).void }
      def initialize(region)
        @region           = T.let(region, Region)
        @block_info_table = T.let({}, T::Hash[Block, BlockInfo])
        @dominator_tree   = T.let(nil, T.nilable(DominatorTree))
      end

      sig { params(block: Block).returns(BlockInfo) }
      def block_info(block)
        raise "block not in region" if block.parent_region != @region
        @block_info_table[block] ||= BlockInfo.new(block)
      end

      sig { returns(DominatorTree) }
      def dominator_tree
        @dominator_tree ||= DominatorTree.new(@region)
      end

      sig { params(a: Operation, b: Operation).returns(T::Boolean) }
      def dominates(a, b)
        block_a = a.parent_block!
        block_b = b.parent_block!
        if block_a == block_b
          block_info(block_a).dominates(a, b)
        else
          block_dominates(block_a, block_b)
        end
      end

      sig { params(a: Block, b: Block).returns(T::Boolean) }
      def block_dominates(a, b)
        dominator_tree.dominates(a, b)
      end
    end

    extend T::Sig

    sig { void }
    def initialize
      @region_info_table = T.let({}, T::Hash[Region, RegionInfo])
    end

    sig { params(region: Region).returns(RegionInfo) }
    def region_info(region)
      @region_info_table[region] ||= RegionInfo.new(region)
    end

    # Get the highest ancestor of operation that is still a descendent of region.
    # Nil if the operation is not a descendent of the region.
    # If the operation is located directly under the region, returns the operation.
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
        b = region.parent_block
        return nil if b.nil?
        block = b
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
    sig { params(a: Block, b: Block, strict: T::Boolean).returns(T::Boolean) }
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
        block_dominates(value.owning_block, operation.parent_block!)
      when Result
        dominates(value.owning_operation, operation, strict: true)
      else
        raise "Unknown class #{value.class.name}"
      end
    end
  end

  class DominanceError < Error
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
      "#{operand} uses value #{operand.get} before it's definition"
    end
  end

  class DominanceVerifier
    extend T::Sig

    # Recursively verify the regions in the operation.
    # Verifies that:
    # - all values are defined before use
    # - the entry block of a region has no predecessors (TODO)
    # - All blocks in a region are reachable (TODO)
    sig { params(root: Operation).returns(T.nilable(Error)) }
    def call(root)
      validate_operation(root, Dominance.new)
    end

    sig { params(operation: Operation, dominance: Dominance).returns(T.nilable(Error)) }
    def validate_operation(operation, dominance)
      error = validate_operands(operation, dominance)
      return OperationError.new(operation, error) if error
      validate_regions(operation, dominance)
    end

    sig { params(operation: Operation, dominance: Dominance).returns(T.nilable(Error)) }
    def validate_operands(operation, dominance)
      operation.operands.each do |operand|
        value = operand.get!
        unless dominance.value_dominates(value, operation)
          return DominanceError.new(operand)
        end
      end
      nil
    end

    sig { params(operation: Operation, dominance: Dominance).returns(T.nilable(Error)) }
    def validate_regions(operation, dominance)
      operation.regions.each do |region|
        error = validate_region(region, dominance)
        return error if error
      end
      nil
    end

    sig { params(region: Region, dominance: Dominance).returns(T.nilable(Error)) }
    def validate_region(region, dominance)
      region.blocks.each do |block|
        block.operations.each do |operation|
          error = validate_operation(operation, dominance)
          return RegionError.new(region, error) if error
        end
      end
      nil
    end
  end

  VerifyDominance = T.let(DominanceVerifier.new, DominanceVerifier)
end
