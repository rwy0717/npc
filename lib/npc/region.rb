# typed: strict
# frozen_string_literal: true

module NPC
  class RegionKind < T::Enum
    enums do
      # executed region type -- normal region.
      Exec = new
      # declarative region type -- graph region.
      Decl = new
    end
  end

  class OperationsInRegion
    extend T::Sig
    extend T::Generic

    include Enumerable

    Elem = type_member { { fixed: Operation } }

    sig { params(region: Region).void }
    def initialize(region)
      @region = T.let(region, Region)
    end

    sig { returns(Region) }
    attr_reader :region

    sig { override.params(proc: T.proc.params(arg0: Operation).returns(BasicObject)).returns(BasicObject) }
    def each(&proc)
      @region.blocks.each do |block|
        block.operations.each do |operation|
          proc.call(operation)
        end
      end
    end
  end

  # Iterator for blocks in region.
  class BlocksInRegion
    extend T::Sig
    extend T::Generic

    include Enumerable

    Elem = type_member { { fixed: Block } }

    sig { params(region: Region).void }
    def initialize(region)
      @next = T.let(region.first_block, T.nilable(Block))
    end

    sig { override.params(proc: T.proc.params(arg0: Block).returns(BasicObject)).returns(BasicObject) }
    def each(&proc)
      block = T.let(@next, T.nilable(Block))
      while block
        n = block.next_block
        proc.call(block)
        block = n
      end
    end
  end

  class Region
    extend T::Sig

    sig do
      params(
        parent_operation: T.nilable(Operation),
      ).void
    end
    def initialize(parent_operation = nil)
      @parent_operation = T.let(parent_operation, T.nilable(Operation))
      @sentinel = T.let(BlockSentinel.new(self), BlockSentinel)
    end

    # The parent/containing-operation of this region.
    # Note: Do not set manually. Use {Operation#append_region(region)}.
    sig { returns(T.nilable(Operation)) }
    attr_accessor :parent_operation

    sig { returns(Operation) }
    def parent_operation!
      T.must(@parent_operation)
    end

    sig { returns(T.nilable(Block)) }
    def parent_block
      parent_operation&.parent_block
    end

    sig { returns(Block) }
    def parent_block!
      parent_operation!.parent_block!
    end

    # The region that contains this region.
    sig { returns(T.nilable(Region)) }
    def parent_region
      parent_block&.parent_region
    end

    sig { returns(Region) }
    def parent_region!
      parent_block!.parent_region!
    end

    sig { returns(T.nilable(Integer)) }
    def index
      parent_operation&.regions&.find_index(self)
    end

    ### Block Management

    # The link before the first block.
    # Can be used as an insertion point for prepending blocks.
    # Works even if the region is empty.
    sig { returns(BlockLink) }
    def front
      @sentinel
    end

    # The link after the last block.
    # Can be used as an insertion point for appending blocks.
    # Works even if the region is empty.
    sig { returns(BlockLink) }
    def back
      @sentinel.prev_link!
    end

    sig { returns(T.nilable(Block)) }
    def first_block
      @sentinel.next_block
    end

    sig { returns(Block) }
    def first_block!
      T.must(first_block)
    end

    sig { returns(T.nilable(Block)) }
    def last_block
      @sentinel.prev_block
    end

    sig { returns(Block) }
    def last_block!
      T.must(last_block)
    end

    sig { returns(T::Boolean) }
    def empty?
      @sentinel.next_link == @sentinel
    end

    sig { returns(T::Boolean) }
    def one_block?
      !empty? && @sentinel.next_link!.next_link! == @sentinel
    end

    sig { returns(BlocksInRegion) }
    def blocks
      BlocksInRegion.new(self)
    end

    ## Insert a block at the beginning of this region. Returns the inserted block.
    sig { params(block: Block).returns(T.self_type) }
    def prepend_block!(block)
      block.insert_into_region!(front)
      self
    end

    ## Insert a block into this region. Returns the inserted block.
    sig { params(block: Block).returns(T.self_type) }
    def append_block!(block)
      block.insert_into_region!(back)
      self
    end

    ## Remove a block from this region.
    sig { params(block: Block).returns(T.self_type) }
    def remove_block!(block)
      raise "block is not a child of this region" if self != block.parent_region

      block.remove_from_region!
      self
    end

    # Allocate a new block at the end of this region.
    sig { params(tys: T::Array[Type]).returns(Block) }
    def new_block(tys)
      block = Block.new(tys)
      block.insert_into_region!(back)
    end

    ### Region Arguments

    ## Arguments of this region. Derived from the arguments of the first block.
    sig { returns(T::Array[Argument]) }
    def arguments
      first_block&.arguments || []
    end

    ### Cloning and Copying

    # Perform a deep copy of this region, and the IR objects under it.
    # The new region will not have a parent operation.
    sig { params(remap_table: RemapTable).returns(T.self_type) }
    def clone(remap_table = RemapTable.new)
      new_region = self.class.new
      clone_into!(new_region, remap_table)
      new_region
    end

    # Copy the IR objects under this region into a new region.
    sig { params(new_region: Region, remap_table: RemapTable).void }
    def clone_into!(new_region, remap_table = RemapTable.new)
      clone_at!(new_region.back, remap_table)
    end

    # Copy the blocks under this region, inserting them at the given cursor.
    sig { params(cursor: BlockLink, remap_table: RemapTable).void }
    def clone_at!(cursor, remap_table = RemapTable.new)
      raise "cannot clone region into itself" if cursor.parent_region == self

      # 1) Copy blocks without copying the operations under them.
      #    Remap all blocks and block arguments.
      insertion_point = cursor
      blocks.each do |block|
        clone_block = Block.new
        remap_table.remap_block!(block, clone_block)

        block.arguments.each do |argument|
          # if the argument has been remapped, then we won't create it here.
          # this can happen if a block argument is being replaced.
          next if remap_table.include_value?(argument)

          clone_argument = Argument.new(nil, argument.type)
          clone_block.append_argument!(clone_argument)
          remap_table.remap_value!(argument, clone_argument)
        end

        clone_block.insert_into_region!(insertion_point)
        insertion_point = clone_block
      end

      # 2) Clone operations without cloning their regions or operands.
      #    Remap the results of these operations before trying to build the operands.

      block       = T.let(first_block,       T.nilable(Block))
      clone_block = T.let(cursor.next_block, T.nilable(Block))
      until block.nil? || clone_block.nil?
        block.operations.each do |operation|
          clone_block.append_operation!(
            operation.clone(
              remap_table,
              clone_regions:  false,
              clone_operands: false,
            )
          )
        end
        block       = block.next_block
        clone_block = clone_block.next_block
      end

      # 3) Clone the operands and regions.
      block       = T.let(first_block,       T.nilable(Block))
      clone_block = T.let(cursor.next_block, T.nilable(Block))

      until block.nil? || clone_block.nil?
        operation       = T.let(block.first_operation,       T.nilable(Operation))
        clone_operation = T.let(clone_block.first_operation, T.nilable(Operation))

        until operation.nil? || clone_operation.nil?
          operation.operands.each do |operand|
            clone_target  = remap_table.get_value(operand.get)
            clone_operand = Operand.new(nil, clone_target)
            clone_operation.append_operand!(clone_operand)
          end

          operation.regions.each do |region|
            clone_region = region.clone(remap_table)
            clone_operation.append_region!(clone_region)
          end

          operation       = operation.next_operation
          clone_operation = clone_operation.next_operation
        end

        block       = block.next_block
        clone_block = clone_block.next_block
      end
    end

    ## Operations in this region

    # An iterator that visits all operations in a region.
    sig { returns(OperationsInRegion) }
    def operations
      OperationsInRegion.new(self)
    end

    sig { returns(String) }
    def inspect
      to_s
    end

    sig { returns(String) }
    def to_s
      id = format("%016x", object_id)
      "#<#{self.class.name}:0x#{id}>"
    end

    sig { void }
    def dump
      Printer.print_region(self)
    end
  end

  # A special kind of region that has no control flow.
  # A graph region must have exactly one block, and that block
  # has no terminators. These properties are checked by the verifier.
  #
  # If an IR has a module op, which holds functions, then
  # the module would have a declarative graph region, while the function
  # would have a normal executable region.
  class GraphRegion < Region
    extend T::Sig
  end
end
