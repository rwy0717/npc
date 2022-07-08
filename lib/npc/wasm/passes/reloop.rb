# typed: strict
# frozen_string_literal: true

module NPC
  module WASM
    #
    # Convert unstructured control flow into WASM-style structured control flow.
    # After this pass, no unstructured goto-style ops are left in the IR.
    # This is necessary for exporting the IR to wasm binaries.
    #
    # Based on the Stackify algorithm in LLVM (not the original Relooper algorithm).
    #
    class ReloopPass
      extend T::Sig
      extend T::Helpers
      include Pass

      sig do
        override.params(
          context: PassContext,
          target:  Operation,
        ).returns(PassResult)
      end
      def run(context, target)
        return PassResult::Failure.new unless target.is_a?(IR::Function)

        puts "*** in reloop pass ***"
        puts "*** getting dominance ***"
        dominance   = context.run_analysis(DominanceAnalysis.instance).value!
        loop_info   = context.run_analysis(LoopAnalysis.instance).value!

        body_region    = target.body_region
        body_loop_info = loop_info.for_region(body_region)

        puts "*** running ***"
        create_loops(body_region, body_loop_info)
        create_blocks(body_region)

        PassResult::Success.new
      end

      private

      # Convert backwards branches to loops and breaks.
      sig { params(region: Region, loop_info: RegionLoopInfo).void }
      def create_loops(region, loop_info)
        puts ">> create_loops"
        puts ">> #{region}"

        puts loop_info.table

        region.blocks.each do |block|
          loop = loop_info.loop_for(block)
          if loop && loop.header_block == block
            create_loop(block, loop)
          end
        end
      end

      sig { params(block: Block, loop: Loop).void }
      def create_loop(block, loop)
        puts ">>> create_loop"
        puts ">>> #{block}"

        loop_op    = IR::BrLoop.build
        loop_body  = loop_op.body

        loop.blocks.each do |block|
          block.move!(loop_body.back)
        end

        loop_body.blocks.each do |b|
          terminator = b.terminator
          next unless terminator.is_a?(IR::Goto)
          next unless terminator.target == block

          terminator.drop!
          b.append_operation!(IR::Br.build(0))
          b.append_operation!(IR::End.build)
        end∂

        entry_block = loop.entering_block
        next unless entry_block

        entry_block.terminator&.drop!
        entry_block.append_operation!(loop_op)
      end

      sig { params(region: Region).void }
      def create_blocks(region)
        puts ">> create_blocks"
        puts ">> #{region}"

        region.blocks.each do |block|
          if block.any_predecessors?
            create_block(block)
          end
        end
      end

      sig { params(block: Block).void }
      def create_block(block)
        puts ">> create_block"
        puts ">> #{block}"

        block.predecessors.each do |predecessor|
          block_op = IR::BrBlock.build([])
          block.prepend_operation!(block_op)

          # Convert the predecessors terminator into something
          # logical.
          terminator = block.terminator!
          terminator&.remove_from_block!

          case terminator
          when IR::Goto
            predecessor.append_operation!(IR::Br.build(0))
            predecessor.append_operation!(IR::End.build)
          when IR::GotoIf
            outer_block_op = IR::BrBlock.new
            inner_block_op = IR::BrBlock.new
            outer_block_op.body_block.append_operation!(inner_block_op)
            inner_block_op.append_operation!(IR::BrIf.build(terminator.test, 0))
            inner_block_op.append_operation!(Br.build(1))

          else
            raise "unhandled terminator type"
          end

          terminator.drop!

          predecessor.move!(block_op.body.front)
          predecessor.terminator&.drop!
          predecessor.append_operation!(IR::Br.build(0))
          predecessor.append_operation!(IR::End.build)
        end
      end
    end
  end
end
