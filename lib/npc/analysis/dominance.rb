# typed: strict
# frozen_string_literal: true

module NPC
  # Information about when a block dominates another in a given region.
  class DominatorTree
    class Node
      extend T::Sig
      include GraphNode

      sig { params(block: Block, index: Integer, parent: T.nilable(Node)).void }
      def initialize(block, index, parent = nil)
        @block    = T.let(block,  Block)
        @parent   = T.let(parent, T.nilable(Node))
        @children = T.let([],     T::Array[Node])
        @index    = T.let(index,  Integer)
      end

      # The block this node represents.
      sig { returns(Block) }
      attr_reader :block

      # The index or "level" of this block.
      sig { returns(Integer) }
      attr_reader :index

      # The nearest dominator. Also called an idom or immediate dominator.
      sig { returns(T.nilable(Node)) }
      attr_reader :parent

      sig { params(parent: Node).void }
      def parent=(parent)
        # raise "cannot set parent of root node" if @parent.nil?
        @parent&.children&.delete(self)
        @parent = parent
        @parent.children << self
      end

      # The nodes which are dominated by this node.
      sig { returns(T::Array[Node]) }
      attr_reader :children

      sig { returns(ArrayIterator[Node]) }
      def children_iter
        ArrayIterator.new(children)
      end

      sig { override.returns(ArrayIterator[Node]) }
      def successors_iter
        children_iter
      end

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
        node = Node.new(block, index)
        nodes << node
        @table[block] = node
      end

      # The entry node dominates itself, has no proper dominators.
      first_node = nodes.pop
      # first_node.parent = first_node

      changed = T.let(true, T::Boolean)
      while changed
        changed = false

        nodes.reverse.each do |node|
          block    = node.block
          new_idom = T.let(nil, T.nilable(Node))

          block.predecessors.each do |pred|
            pred_node = @table.fetch(pred)
            if pred_node.parent || pred_node == first_node
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

    sig { params(block: Block).returns(T::Boolean) }
    def reachable?(block)
      table.key?(block)
    end

    # True if a improperly dominates b.
    # That is, returns true if a and b are the same block.
    sig { params(a: Block, b: Block).returns(T::Boolean) }
    def dominates?(a, b)
      node = @table.fetch(b)
      until a == node.block
        parent = node.parent
        return false unless parent

        node = parent
      end
      true
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

  DominanceInfo = T.type_alias { Dominance }

  # TODO: Rename to DominanceInfo.
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
        @block       = block
        @index_table = T.let({}, T::Hash[Operation, Integer])

        block.operations.each_with_index do |operation, index|
          @index_table[operation] = index
        end
      end

      sig { params(a: Operation, b: Operation).returns(T::Boolean) }
      def dominates?(a, b)
        raise "operation not in block" if
          a.parent_block != @block || b.parent_block != @block

        @index_table.fetch(a) < @index_table.fetch(b)
      end

      sig { params(a: Operation, b: Operation).returns(T::Boolean) }
      def properly_dominates?(a, b)
        a != b && dominates?(a, b)
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
      def dominates?(a, b)
        block_a = a.parent_block!
        block_b = b.parent_block!
        if block_a == block_b
          block_info(block_a).dominates?(a, b)
        else
          block_dominates?(block_a, block_b)
        end
      end

      sig { params(a: Block, b: Block).returns(T::Boolean) }
      def block_dominates?(a, b)
        dominator_tree.dominates?(a, b)
      end

      sig { params(block: Block).returns(T::Boolean) }
      def block_reachable?(block)
        dominator_tree.reachable?(block)
      end
    end

    extend T::Sig

    sig { void }
    def initialize
      @region_info_table = T.let({}, T::Hash[Region, RegionInfo])
    end

    sig { params(region: Region).returns(RegionInfo) }
    def for_region(region)
      region_info(region)
    end

    # TODO: Replace with for_region.
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
    def dominates?(a, b, strict: false)
      block_a = a.parent_block!
      region_a = block_a.parent_region!
      b = ancestor_in_region(b, region_a)
      return false if b.nil?
      return !strict if a == b

      region_info(region_a).dominates?(a, b)
    end

    # Test if operation a is "before" operation b.
    # a dominates any descendent (inner) operations, but not itself.
    # This is in contrast to:
    # - strict domination, where a would not dominate inner operations.
    # - non-strict domination, where a is considered to dominate itself.
    sig { params(a: Operation, b: Operation).returns(T::Boolean) }
    def properly_dominates?(a, b)
      return false if a == b

      dominates?(a, b, strict: false)
    end

    # Does the block a come "before" block b?
    # If determining non-strict domination, then:
    #   a dominates itself and any descendent (inner) blocks.
    # If determining strict domination, then:
    #   a does not dominate itself, or any descendent operations.
    # Determines non-strict domination by default.
    sig { params(a: Block, b: Block, strict: T::Boolean).returns(T::Boolean) }
    def block_dominates?(a, b, strict: false)
      region_a = a.parent_region!
      b = block_ancestor_in_region(b, region_a)
      return false if b.nil?
      return !strict if a == b

      region_info(region_a).block_dominates?(a, b)
    end

    # Is the value defined before an operation, such that the value can be used
    # as an operand to the operation.
    sig { params(value: Value, operation: Operation).returns(T::Boolean) }
    def value_dominates?(value, operation)
      case value
      when Argument
        defining_block = value.parent_block
        return false unless defining_block

        block_dominates?(defining_block, operation.parent_block!)
      when Result
        defining_operation = value.parent_operation
        return false unless defining_operation

        dominates?(defining_operation, operation, strict: true)
      else
        raise "Unknown class #{value.class.name}"
      end
    end

    # Is the block reachable from the entry block of it's region?
    sig { params(block: Block).returns(T::Boolean) }
    def block_reachable?(block)
      # The dominance tree only includes blocks that are reachable
      # from the root. To determine reachability, build the table,
      # and test if the block is in the table.
      region = block.parent_region
      return false if region.nil?

      region_info(region).block_reachable?(block)
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

  class DominanceAnalysis
    extend T::Sig
    extend T::Helpers
    extend T::Generic
    include Analysis
    include Singleton

    Value = type_member { { fixed: Dominance } }

    sig do
      override.params(
        _context: AnalysisContext,
        _target:  Operation,
      ).returns(AnalysisResult[Dominance])
    end
    def run(_context, _target)
      AnalysisResult::Success.new(Dominance.new)
    end
  end

  class DominanceVerifier
    extend T::Sig

    # Recursively verify the regions in the operation.
    # Verifies that:
    # - all values are defined before use
    # - All blocks in a region are reachable
    sig { params(root: Operation).returns(T.nilable(Error)) }
    def call(root)
      verify_operation(root, Dominance.new)
    end

    sig { params(operation: Operation, dominance: Dominance).returns(T.nilable(Error)) }
    def verify_operation(operation, dominance)
      error = verify_operands(operation, dominance)
      return OperationError.new(operation, error) if error

      verify_regions(operation, dominance)
    end

    sig { params(operation: Operation, dominance: Dominance).returns(T.nilable(Error)) }
    def verify_operands(operation, dominance)
      operation.operands.each do |operand|
        value = operand.get!
        unless dominance.value_dominates?(value, operation)
          return DominanceError.new(operand)
        end
      end
      nil
    end

    sig { params(operation: Operation, dominance: Dominance).returns(T.nilable(Error)) }
    def verify_regions(operation, dominance)
      operation.regions.each do |region|
        error = verify_region(region, dominance)
        return error if error
      end
      nil
    end

    sig { params(region: Region, dominance: Dominance).returns(T.nilable(Error)) }
    def verify_region(region, dominance)
      entry_block = region.first_block
      return nil if entry_block.nil?

      # Reachability

      block = T.let(entry_block.next_block, T.nilable(Block))
      while block
        unless dominance.block_reachable?(block)
          return RegionError.new(region,
            BlockError.new(block, "not reachable from region's entry block"))
        end
        block = block.next_block
      end

      # Value domination checks

      region.blocks.each do |block|
        block.operations.each do |operation|
          error = verify_operation(operation, dominance)
          return RegionError.new(region, BlockError.new(block, error)) if error
        end
      end
      nil
    end
  end

  VerifyDominance = T.let(DominanceVerifier.new, DominanceVerifier)
end
