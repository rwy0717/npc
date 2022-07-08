# typed: strict
# frozen_string_literal: true

module NPC
  # A description of a loop in the IR.
  # See: https://llvm.org/docs/LoopTerminology.html
  class Loop
    extend T::Sig

    sig { params(header_block: Block, parent: T.nilable(Loop)).void }
    def initialize(header_block, parent = nil)
      @header_block = T.let(header_block, Block)
      @parent       = T.let(parent,       T.nilable(Loop))

      # The blocks and children are populated in a secondary pass over the CFG.
      # These lists are sorted in reverse post-order.
      @blocks   = T.let([], T::Array[Block])
      @children = T.let([], T::Array[Loop])
    end

    # The immediate parent loop.
    # If this loop is the outermost loop, then parent is nil.
    sig { returns(T.nilable(Loop)) }
    attr_accessor :parent

    # sig { params(parent: T.nilable(Loop)).void }
    # def parent=(parent)
    #   @parent = parent
    #   @parent&.children&.add(self)
    # end

    sig { returns(Loop) }
    def parent!
      T.must(@parent)
    end

    # Any loops nested under this loop.
    sig { returns(T::Array[Loop]) }
    attr_reader :children

    # The outermost loop structure.
    # If this loop has no parent, then this loop is the root.
    sig { returns(Loop) }
    def root
      root   = T.let(self, Loop)
      parent = T.let(root.parent, T.nilable(Loop))
      while parent
        root   = parent
        parent = root.parent
      end
      root
    end

    # @!group Blocks in this Loop

    # The set of blocks in this loop.
    sig { returns(T::Array[Block]) }
    attr_reader :blocks

    # Is the given block in this loop?
    # This loops including blocks located in nested loops.
    sig { params(block: Block).returns(T::Boolean) }
    def include?(block)
      @blocks.include?(block)
    end

    # Is the given block outside this loop?
    sig { params(block: Block).returns(T::Boolean) }
    def exclude?(block)
      !@blocks.include?(block)
    end

    # @!group The Header Block

    # True if the given block is the header of this loop.
    sig { params(block: Block).returns(T::Boolean) }
    def header_block?(block)
      @header_block == block
    end

    # The entrypoint and first block in the loop.
    # Dominates all blocks in the loop.
    # A loop has exactly one header.
    sig { returns(Block) }
    attr_reader :header_block

    # @!group Latch Blocks

    # Does the given block occur in the loop, and branch backwards to the loop header?
    sig { params(block: Block).returns(T::Boolean) }
    def latch_block?(block)
      include?(block) && block.successors.include?(header_block)
    end

    # The blocks in this loop that branch back to the header block.
    sig { returns(T::Array[Block]) }
    def latch_blocks
      result = T.let([], T::Array[Block])
      @blocks.each do |block|
        if block.successors.include?(header_block)
          result << block
        end
      end
      result
    end

    # If this loop has exactly one latch block, return it. Otherwise nil.
    sig { returns(T.nilable(Block)) }
    def latch_block
      b = latch_blocks
      b.size == 1 ? b.first : nil
    end

    # The single latch block for this loop.
    # Raises if there is not exactly one latch block.
    sig { returns(Block) }
    def latch_block!
      T.must(latch_block)
    end

    # @!group Exiting Blocks

    # Does the given block occur in the loop, and branch out of the loop?
    sig { params(block: Block).returns(T::Boolean) }
    def exiting_block?(block)
      include?(block) && block.successors.any? { |successor| exclude?(successor) }
    end

    # The blocks in this loop that branch out of this loop.
    # Exiting blocks have a successor outside of this loop.
    sig { returns(T::Array[Block]) }
    def exiting_blocks
      result = T.let([], T::Array[Block])
      @blocks.each do |block|
        if block.successors.any? { |successor| exclude?(successor) }
          result << block
        end
      end
      result
    end

    # If this loop has exactly one exiting block, get it.
    # Otherwise returns nil.
    sig { returns(T.nilable(Block)) }
    def exiting_block
      b = exiting_blocks
      b.length == 1 ? b.first : nil
    end

    # @!group Exit Blocks

    # Does this block have a predecessor inside the loop?
    # The given block must be outside the loop.
    sig { params(block: Block).returns(T::Boolean) }
    def exit_block?(block)
      exclude?(block) && block.predecessors.any? do |predecessor|
        include?(predecessor)
      end
    end

    # The blocks outside this loop that are branched to from in this loop.
    sig { returns(T::Array[Block]) }
    def exit_blocks
      result = T.let([], T::Array[Block])
      @blocks.each do |block|
        block.successors.each do |successor|
          unless @blocks.include?(successor)
            result << successor
          end
        end
      end
      result
    end

    # If this loop has exactly one exit block, get it.
    sig { returns(T.nilable(Block)) }
    def exit_block
      b = exit_blocks
      return nil if b.length != 1

      b.first
    end

    # Does this loop have any exit blocks?
    sig { returns(T::Boolean) }
    def any_exit_blocks?
      @blocks.any? do |block|
        block.successors.any? do |successor|
          exclude?(successor)
        end
      end
    end

    sig { returns(T::Boolean) }
    def no_exit_blocks?
      !any_exit_blocks?
    end

    sig { returns(T::Array[Block]) }
    def non_latch_exiting_blocks
      exit_blocks - latch_blocks
    end

    # Is the given block an "entering block".
    # IE is it a block that branches to the loop header, but is outside the loop.
    sig { params(block: Block).returns(T::Boolean) }
    def entering_block?(block)
      header_block.predecessors.include?(block) && exclude?(block)
    end

    sig { returns(T::Array[Block]) }
    def entering_blocks
      result = T.let([], T::Array[Block])
      header_block.predecessors.each do |predecessor|
        result << predecessor if exclude?(predecessor)
      end
      result
    end

    sig { returns(T.nilable(Block)) }
    def entering_block
      blocks = entering_blocks
      blocks.first if blocks.length == 1
    end

    sig { returns(Block) }
    def entering_block!
      T.must(entering_block)
    end
  end

  # Information about the loop formed by the blocks in a region.
  class RegionLoopInfo
    extend T::Sig

    sig { params(region: Region, dom_tree: DominatorTree).void }
    def initialize(region, dom_tree)
      @region = T.let(region, Region)
      @table  = T.let({},     T::Hash[Block, Loop])
      @loops  = T.let([],     T::Array[Loop])
      @roots  = T.let([],     T::Array[Loop])
      build(dom_tree)
    end

    # The region that this loop-info knows about.
    sig { returns(Region) }
    attr_reader :region

    # All loops in the region.
    sig { returns(T::Array[Loop]) }
    attr_reader :loops

    # The root loops in the region.
    sig { returns(T::Array[Loop]) }
    attr_reader :roots

    # The table that maps a block to the innermost loop that contains it.
    sig { returns(T::Hash[Block, Loop]) }
    attr_reader :table

    # If the given block is in a loop, return the loop object.
    # Returns nil if the block is not in a loop.
    # The block must be located in this region.
    sig { params(block: Block).returns(T.nilable(Loop)) }
    def loop_for(block)
      raise "block not in region" unless @region == block.parent_region

      @table[block]
    end

    private

    sig { params(dom_tree: DominatorTree).void }
    def build(dom_tree)
      build_loops(dom_tree)
      populate_loops
    end

    # Build the loop table.
    sig { params(dom_tree: DominatorTree).void }
    def build_loops(dom_tree)
      root = @region.first_block
      return unless root

      # In order to detect the nesting of loops, we walk the dom tree
      # in post-order. This means that, blocks who are dominated are
      # visited before their dominators. The inner loops will be dominated
      # by the outer loop headers, so this ensures that inner loops have been
      # found before we attempt to build the outer loop.

      iter = PostOrderGraphIter.new(dom_tree.node(root))
      iter.each! do |node|
        try_build_loop(dom_tree, node)
      end

      # Now that the loops have been built, stash a list of
      # the roots with no parents.

      @roots = @loops.select do |loop|
        loop.parent.nil?
      end
    end

    # Try to build a loop who's header is the given block/node.
    sig { params(dom_tree: DominatorTree, node: DominatorTree::Node).returns(T.nilable(Loop)) }
    def try_build_loop(dom_tree, node)
      # The header block is the entry to the loop, and dominates
      # all the blocks within the loop. *If* we have a loop, this
      # is the header.
      header_block = node.block

      # A latch is a block that branches backwards to the header:
      #   1. It is a predecessor to the header (ie branches to the header)
      #   2. It is dominated by the header     (ie branch is backwards)
      # If the header branches to itself, then it is both a latch and header.
      latch_blocks = header_block.predecessors.select do |predecessor|
        dom_tree.dominates?(header_block, predecessor)
      end

      # For a loop to form, we must have at least one backwards branch.
      return if latch_blocks.empty?

      build_loop(header_block, latch_blocks)
    end

    # Build a loop with the given header block and latch blocks.
    # The block->loop mapping will be established,
    # but the loop->block mapping will be left unpopulated.
    # Assign blocks to loops, adding all the blocks between the header and the latches.
    # Also, discover any subloops, and assign them to their children.
    # Note that the block set for the new loop hasn't been
    sig do
      params(
        header_block: Block,
        latch_blocks: T::Array[Block],
      ).returns(Loop)
    end
    def build_loop(header_block, latch_blocks)
      new_loop = Loop.new(header_block)

      worklist = latch_blocks.dup
      until worklist.empty?
        block   = T.must(worklist.pop)
        subloop = table[block]
        if subloop
          subloop = subloop.root
          map_subloop(new_loop, subloop, worklist) if subloop != new_loop
        else
          map_block(new_loop, block, worklist)
        end
      end

      @loops << new_loop
      new_loop
    end

    # Associate the given subloop as a child of the new_loop.
    sig { params(new_loop: Loop, subloop: Loop, worklist: T::Array[Block]).void }
    def map_subloop(new_loop, subloop, worklist)
      subloop.parent = new_loop
      subloop.header_block.predecessors.each do |predecessor|
        # we can't use subloop.entering_blocks because the subloop isn't populated yet.
        predecessor_loop = @table[predecessor]
        worklist << predecessor unless predecessor_loop == subloop
      end
    end

    # Associate the given block with the new loop in the block->loop mapping.
    sig { params(new_loop: Loop, block: Block, worklist: T::Array[Block]).void }
    def map_block(new_loop, block, worklist)
      @table[block] = new_loop
      return if new_loop.header_block == block

      block.predecessors.each do |predecessor|
        worklist << predecessor
      end
    end

    # Fill in every loop's block set.
    # Each loop's block set is populated in depth-first post-order.
    sig { void }
    def populate_loops
      root_block = @region.first_block
      return unless root_block

      iter = PostOrderGraphIter.new(root_block)
      iter.each! do |block|
        insert_block_into_loops(block)
      end
    end

    # Insert the given block into the loops it belongs to.
    sig { params(block: Block).void }
    def insert_block_into_loops(block)
      loop = @table[block]
      return unless loop

      # Add the block to all the loops it's under.

      iter = T.let(loop, T.nilable(Loop))
      while iter
        puts "inserting #{block} into #{iter}"
        iter.blocks << block
        iter = iter.parent
      end

      # If we hit the loop header, we're done inserting children
      # and blocks into the loop. Reverse the lists to put them
      # in reverse post order.

      if loop.header_block == block
        parent = loop.parent
        parent.children << loop if parent

        loop.blocks.reverse!
        loop.children.reverse!
      end
    end
  end

  # Information about the loops under an operation.
  class LoopInfo
    extend T::Sig

    sig { params(dominance_info: DominanceInfo).void }
    def initialize(dominance_info)
      @dominance_info = T.let(dominance_info, DominanceInfo)
      @region_table   = T.let({}, T::Hash[Region, RegionLoopInfo])
    end

    # Get information about loops formed by the blocks under a region.
    # RegionLoopInfo is computed lazily.
    sig { params(region: Region).returns(RegionLoopInfo) }
    def for_region(region)
      @region_table[region] ||= RegionLoopInfo.new(region, dominator_tree(region))
    end

    sig { params(block: Block).returns(T.nilable(Loop)) }
    def loop_for(block)
      for_region(block.parent_region!).loop_for(block)
    end

    private

    sig { params(region: Region).returns(DominatorTree) }
    def dominator_tree(region)
      @dominance_info.for_region(region).dominator_tree
    end
  end

  class LoopAnalysis
    extend T::Sig
    extend T::Generic
    include Analysis
    include Singleton

    Value = type_member { { fixed: LoopInfo } }

    sig do
      override.params(
        context: AnalysisContext,
        target:  Operation,
      ).returns(AnalysisResult[LoopInfo])
    end
    def run(context, target)
      dominance_info = context.run_analysis(DominanceAnalysis.instance).value!
      AnalysisResult::Success.new(LoopInfo.new(dominance_info))
    end
  end
end
