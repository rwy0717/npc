# typed: strict
# frozen_string_literals: true
# frozen_string_literal: true

module NPC
  module WASM
    # An edge between two blocks.
    class Edge
      extend T::Sig
      extend T::Helpers

      sig { params(pred: Block, succ: Block).void }
      def initialize(pred, succ)
        @pred = T.let(pred, Block)
        @succ = T.let(succ, Block)
      end

      sig { returns(Block) }
      attr_accessor :pred

      sig { returns(Block) }
      attr_accessor :succ
    end

    # Reachability within a "zone" (region in relooper terms), which is:
    # 1) a group of blocks with a single entrypoint, and
    # 2) there are no branches back to the entrypoint, from inside the zone.
    class BlockReachabilityGraph
      extend T::Sig
      extend T::Helpers

      sig { params(entry: Block, blocks: T::Set[Block]).void }
      def initialize(entry, blocks)
        @entry  = T.let(entry,  Block)
        @blocks = T.let(blocks, T::Set[Block])
        @table  = T.let({},     T::Hash[Block, T::Set[Block]])

        @loop_blocks          = T.let(Set[], T::Set[Block])
        @loop_header_blocks   = T.let(Set[], T::Set[Block])
        @loop_entering_blocks = T.let(Set[], T::Set[Block])
      end

      sig { returns(T::Set[Block]) }
      attr_reader :blocks

      sig { params(block: Block).returns(T::Boolean) }
      def in_zone?(block)
        @blocks.include?(block)
      end

      sig { params(block: Block).returns(T::Set[Block]) }
      def reachable_blocks(block)
        @table[block] ||= Set.new
      end

      # Is block b reachable from a?
      sig { params(a: Block, b: Block).returns(T::Boolean) }
      def reachable?(a, b)
        raise "not in zone" unless in_zone?(a) && in_zone?(b)

        reachable_blocks(a).include?(b)
      end

      # is block b reachable from block a, and vice versa, is block a reachable from block b?
      sig { params(a: Block, b: Block).returns(T::Boolean) }
      def mutually_reachable?(a, b)
        reachable?(a, b) && reachable?(b, a)
      end

      # the entrypoint block at the beginning of the zone.
      sig { returns(Block) }
      def entry_block
        @entry
      end

      # The blocks that participate in, or are located inside, a loop.
      sig { returns(T::Set[Block]) }
      attr_reader :loop_blocks

      sig { params(block: Block).returns(T::Boolean) }
      def loop_block?(block)
        @loop_blocks.include?(block)
      end

      # The blocks that are reachable from outside the loop.
      sig { returns(T::Set[Block]) }
      attr_reader :loop_header_blocks

      # The blocks that enter a loop from outside.
      sig { returns(T::Set[Block]) }
      attr_reader :loop_entering_blocks

      private

      sig { void }
      def build
        # 1) Record reachability
        # From a given block, which blocks are reachable?
        # Start by adding all direct edges to the worklist.

        worklist = T.let([], T::Array[Edge])

        @blocks.each do |block|
          block.successors.each do |successor|
            next unless successor != @entry && in_zone?(successor)

            if reachable_blocks(@entry).add?(successor)
              worklist.push(Edge.new(block, successor))
            end
          end
        end

        until worklist.empty?
          edge      = T.must(worklist.pop)
          block     = edge.pred
          successor = edge.succ
          raise "not in zone" unless in_zone?(block) && in_zone?(successor)

          # 1) For each edge A -> B in a graph:
          # P0...PN -> A -> B
          # Record that B is reachable from the predecessors of A, P0...PN.
          # And push the edges P0...PN -> B onto the workstack.

          next unless block != @entry

          block.predecessors.each do |predecessor|
            if reachable_blocks(predecessor).add?(successor)
              worklist.push(Edge.new(predecessor, successor))
            end
          end
        end

        # 2) Find the blocks participating in a loop
        # If a block is reachable from itself, it is a loop_block.

        @table.each do |block, reachable_blocks|
          if reachable_blocks.include?(block)
            loop_blocks.add(block)
          end
        end

        raise "entry point is a looping block" if loop_blocks.include?(@entry)

        # 3) Find the "loop header blocks" and "loop entering blocks"
        # Loop header blocks: these are the blocks inside loops that are branched to from outside the loop.
        # Loop entering blocks: blocks that branch to a loop header, from outside the loop.

        loop_blocks.each do |block|
          block.predecessors.each do |predecessor|
            # If the predecessor is not reachable from the block,
            # then the predecessor is
            unless reachable?(block, predecessor)
              loop_header_blocks.add(block)
              loop_entering_blocks.add(predecessor)
            end
          end
        end
      end
    end

    class RegionReachabilityInfo
      extend T::Sig
      extend T::Helpers

      sig { params(region: Region).void }
      def initialize(region)
        region.blocks.each do |block|
          block.successors.each do |successor|
            if successor != block && successor.parent_region == region
              p("do_something")
            end
          end
        end
      end
    end

    class ReachabilityInfo
      extend T::Sig
      extend T::Helpers

      sig { void }
      def initialize
        @table = T.let({}, T::Hash[Region, RegionReachabilityInfo])
      end

      sig { params(region: Region).returns(RegionReachabilityInfo) }
      def for_region(region)
        @table[region] ||= RegionReachabilityInfo.new(region)
      end
    end

    class ReachabilityAnalysis
      extend T::Sig
      extend T::Helpers
      extend T::Generic
      include Analysis

      Value = type_member { { fixed: ReachabilityInfo } }

      sig do
        override.params(
          context: AnalysisContext,
          target:  Operation,
        ).returns(AnalysisResult[ReachabilityInfo])
      end
      def run(context, target)
        AnalysisResult::Success.new(ReachabilityInfo.new)
      end
    end

    # Fix irreducible control flow.
    class FixControlFlow
      extend T::Sig
      extend T::Helpers
      include Pass

      sig do
        override.params(
          _context: PassContext,
          target:   Operation,
        ).returns(PassResult)
      end
      def run(_context, target)
        return PassResult.failure unless target.is_a?(IR::Function)

        fix_in_region(target.body_region)
        PassResult.success
      end

      private

      sig { params(region: Region).returns(T::Boolean) }
      def fix_in_region(region)
        blocks = T.let(Set[], T::Set[Block])

        region.blocks.each do |block|
          blocks.add(block)
        end

        # fix_in_zone(entry, blocks)
        false
      end

      sig { params(entry: Block, blocks: T::Set[Block]).returns(T::Boolean) }
      def fix_in_zone(entry, blocks)
        changed = T.let(true, T::Boolean)
        while changed
          changed = false
          graph   = BlockReachabilityGraph.new(entry, blocks)

          # a -> b
          # a -> c
          # b -> c
          # c -> b

          graph.blocks.each do |block|
            next unless graph.loop_header_blocks.include?(block)

            mutual_loop_headers = T.let(Set[], T::Set[Block])
            graph.loop_header_blocks.each do |other|
              if other != block && graph.mutually_reachable?(block, other)
                mutual_loop_headers.add(other)
              end
            end

            if mutual_loop_headers.any?
              make_single_entry_loop(mutual)
            end
          end
        end
      end

      # given a
      # sig do
      #   params(
      #     region:  Region,
      #     entries:
      #   )
      # end
      # def make_single_entry_loop(region, entries, blocks, graph)
      #   region.asfd
      # end
    end
  end
end
