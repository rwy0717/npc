# typed: true
# frozen_string_literal: true

module NPC
  class NameTableState < T::Struct
    extend T::Sig

    prop :next_value_id, Integer, default: 0

    sig { returns(String) }
    def new_value_name!
      name = @next_value_id.to_s
      @next_value_id += 1
      name
    end
  end

  class NameTableStack < T::Struct
    extend T::Sig

    const :frames, T::Array[NameTableState], factory: -> { [] }

    sig { returns(T.nilable(NameTableState)) }
    def state
      frames.first
    end

    sig { returns(NameTableState) }
    def state!
      T.must(frames.first)
    end

    sig { returns(NameTableState) }
    def new_state
      x = state
      x ? x.dup : NameTableState.new
    end

    sig { void }
    def enter_region
      frames.unshift(new_state)
    end

    sig { void }
    def leave_region
      frames.shift
    end

    sig { params(proc: T.proc.void).void }
    def in_region(&proc)
      enter_region
      proc.call
      leave_region
    end

    sig { returns(String) }
    def new_value_name!
      state!.new_value_name!
    end
  end

  class NameTable < T::Struct
    extend T::Sig

    const :value_names,  T::Hash[Value, String], factory: -> { {} }
    const :block_names,  T::Hash[Block, String], factory: -> { {} }
    const :region_names, T::Hash[Region, String], factory: -> { {} }

    prop :next_unknown_id, Integer, default: 0

    sig { params(value: Value).returns(String) }
    def value_name(value)
      name = value_names[value]
      return name if name

      name = "?#{@next_unknown_id}"
      value_names[value] = name
      @next_unknown_id += 1
      name
    end

    sig { params(block: Block).returns(String) }
    def block_name(block)
      name = block_names[block]
      raise "unnamed block" unless name
      name
    end

    sig { params(region: Region).returns(String) }
    def region_name(region)
      name = region_names[region]
      raise "unnamed block" unless name
      name
    end

    sig { params(value: Value, name: String).void }
    def name_value!(value, name)
      raise "value aleady named" if value_names.key?(value)
      value_names[value] = name
    end

    sig { params(block: Block, name: String).void }
    def name_block!(block, name)
      raise "block aleady named" if block_names.key?(block)
      block_names[block] = name
    end

    sig { params(region: Region, name: String).void }
    def name_region!(region, name)
      raise "region aleady named" if region_names.key?(region)
      region_names[region] = name
    end
  end

  class Namer
    class << self
      extend T::Sig

      # Build a name-table for all the IR objects defined by the operation.
      sig { params(operation: Operation).returns(NameTable) }
      def name_in_operation(operation)
        table = NameTable.new
        namer = Namer.new(table)
        namer.name_in_operation!(operation)
        table
      end

      # Build a name-table for all the IR objects defined by the block.
      sig { params(block: Block).returns(NameTable) }
      def name_in_block(block)
        table = NameTable.new
        namer = Namer.new(table)
        namer.name_in_block!(block)
        table
      end

      # Build a name-table for all the IR objects defined in the region.
      sig { params(region: Region).returns(NameTable) }
      def name_in_region(region)
        table = NameTable.new
        namer = Namer.new(table)
        namer.name_in_region!(region)
        table
      end
    end

    extend T::Sig

    sig { params(table: NameTable).void }
    def initialize(table)
      @stack = T.let(NameTableStack.new, NameTableStack)
      @table = T.let(table, NameTable)
    end

    sig { returns(NameTable) }
    attr_reader :table

    sig { returns(NameTableStack) }
    attr_reader :stack

    sig { params(operation: Operation).void }
    def name_in_operation!(operation)
      operation.results.each do |result|
        table.name_value!(result, stack.new_value_name!)
      end

      operation.regions.each_with_index do |region, index|
        table.name_region!(region, "region#{index}")
        name_in_region!(region)
      end
    end

    sig { params(region: Region).void }
    def name_in_region!(region)
      stack.in_region do
        region.blocks.each_with_index do |block, index|
          table.name_block!(block, "block#{index}")
          name_in_block!(block)
        end
      end
    end

    sig { params(block: Block).void }
    def name_in_block!(block)
      block.arguments.each do |argument|
        table.name_value!(argument, stack.new_value_name!)
      end

      block.operations.each do |operation|
        name_in_operation!(operation)
      end
    end
  end

  class Printer
    class << self
      extend T::Sig

      sig { params(operation: Operation, table: NameTable, out: T.any(StringIO, IO)).void }
      def print_operation(
        operation,
        table: Namer.name_in_operation(operation),
        out: $stdout
      )
        Printer.new(table, out: out).print_operation(operation)
      end

      sig { params(block: Block, table: NameTable, out: T.any(StringIO, IO)).void }
      def print_block(
        block,
        table: Namer.name_in_block(block),
        out: $stdout
      )
        Printer.new(table, out: out).print_block_inline(block)
      end

      sig { params(region: Region, table: NameTable, out: T.any(StringIO, IO)).void }
      def print_region(
        region,
        table: Namer.name_in_region(region),
        out: $stdout
      )
        Printer.new(table, out: out).print_region_inline(region)
      end
    end

    INDENTATION = "  "

    extend T::Sig

    sig { params(table: NameTable, out: T.any(StringIO, IO)).void }
    def initialize(table, out: $stdout)
      @out = T.let(out, T.any(StringIO, IO))
      @indentation_level = 0
      @table = T.let(table, NameTable)
    end

    sig { params(operation: Operation).returns(T.self_type) }
    def print_operation(operation)
      print("\n")
      print_indentation

      if operation.results.any?
        print_results(operation.results)
        print(" = ")
      end

      print(operation.operator_name)

      if operation.attributes.any?
        print_attributes(operation.attributes)
      end

      if operation.operands.any?
        print_operands(operation.operands)
      end

      if operation.block_operands.any?
        print_block_operands(operation.block_operands)
      end

      case operation.regions.length
      when 0 # do nothing
      when 1
        print(" ")
        print_region_inline(operation.region(0))
      else
        indent do
          print_regions(operation.regions)
        end
      end

      print(";")
    end

    sig { params(type: Type).returns(T.self_type) }
    def print_type(type)
      print(type.name)
    end

    sig { params(results: T::Array[Result]).returns(T.self_type) }
    def print_results(results)
      first = T.let(true, T::Boolean)
      results.each do |result|
        print(", ") unless first
        first = false
        print_result(result)
      end
      self
    end

    sig { params(result: Result).returns(T.self_type) }
    def print_result(result)
      print_value_name(result)
      print(": ")
      type = result.type
      if type
        print_type(type)
      else
        print("???")
      end
    end

    sig { params(attributes: T::Hash[Symbol, T.untyped]).returns(T.self_type) }
    def print_attributes(attributes)
      print("[")

      first = T.let(true, T::Boolean)
      attributes.each do |key, val|
        print(", ") unless first
        first = false
        print_attribute(key, val)
      end

      print("]")
    end

    sig { params(key: Symbol, val: T.untyped).returns(T.self_type) }
    def print_attribute(key, val)
      print(key)
      print(": ")
      print(val)
    end

    sig { params(operands: T::Array[Operand]).returns(T.self_type) }
    def print_operands(operands)
      print("(")

      first = T.let(true, T::Boolean)
      operands.each do |operand|
        print(", ") unless first
        first = false
        print_operand(operand)
      end

      print(")")
    end

    sig { params(operand: Operand).returns(T.self_type) }
    def print_operand(operand)
      value = operand.get
      if value
        print_value_name(value)
      else
        print("%?")
      end
      self
    end

    sig { params(block_operands: T::Array[BlockOperand]).returns(T.self_type) }
    def print_block_operands(block_operands)
      print("(")

      first = T.let(true, T::Boolean)
      block_operands.each do |block_operand|
        print(", ") unless first
        first = false
        print_block_operand(block_operand)
      end

      print(")")
    end

    sig { params(block_operand: BlockOperand).returns(T.self_type) }
    def print_block_operand(block_operand)
      block = block_operand.get
      if block
        print_block_name(block)
      else
        print("^?")
      end
      self
    end

    sig { params(regions: T::Array[Region]).returns(T.self_type) }
    def print_regions(regions)
      regions.each do |region|
        print("\n")
        print_indentation
        print_region(region)
      end
      self
    end

    # sig { params(regions: T::Array[Region]).returns(T.self_type) }
    # def print_many_regions(regions)
    # end

    sig { params(region: Region).returns(T.self_type) }
    def print_region(region)
      print("&")
      print(table.region_name(region))
      print(" ")
      print_region_contents(region)
      self
    end

    sig { params(region: Region).returns(T.self_type) }
    def print_region_inline(region)
      print_region_contents(region)
      self
    end

    sig { params(region: Region).returns(T.self_type) }
    def print_region_contents(region)
      # print the inner objects of the region, but not the label.
      print("{")

      if region.empty?
        print("}")
        return self
      end

      if region.one_block?
        block = region.first_block!
        if block.unused?
          print(" ")
          indent { print_block_inline(block) }
          print("\n")
          print_indentation
          print("}")
          return self
        end
      end

      indent { print_blocks(region.blocks) }
      print("\n")
      print_indentation
      print("}")

      self
    end

    sig { params(blocks: BlocksInRegion).returns(T.self_type) }
    def print_blocks(blocks)
      blocks.each do |block|
        print("\n")
        print_indentation
        print_block(block)
      end
      self
    end

    sig { params(block: Block).returns(T.self_type) }
    def print_block(block)
      print("^")
      print(table.block_name(block))
      if block.arguments.any?
        print_arguments(block.arguments)
      end
      print(":")
      indent do
        print_operations(block.operations)
      end
    end

    sig { params(block: Block).returns(T.self_type) }
    def print_block_inline(block)
      if block.arguments.any?
        print_arguments(block.arguments)
        print(" ->")
      end
      print_operations(block.operations)
    end

    sig { params(arguments: T::Array[Argument]).returns(T.self_type) }
    def print_arguments(arguments)
      print("(")

      first = T.let(true, T::Boolean)
      arguments.each do |argument|
        print(", ") unless first
        first = false
        print_argument(argument)
      end

      print(")")
      self
    end

    sig { params(argument: Argument).returns(T.self_type) }
    def print_argument(argument)
      print_value_name(argument)
      print(": ")
      type = argument.type
      if type
        print_type(type)
      else
        print("???")
      end
    end

    sig { params(operations: OperationsInBlock).returns(T.self_type) }
    def print_operations(operations)
      operations.each do |operation|
        print_operation(operation)
      end
      self
    end

    sig { params(value: Value).returns(T.self_type) }
    def print_value_name(value)
      print("%")
      print(table.value_name(value))
    end

    sig { params(block: Block).void }
    def print_block_name(block)
      print("^")
      print(table.block_name(block))
    end

    sig { params(region: Region).returns(T.self_type) }
    def print_region_name(region)
      print("&")
      print(table.region_name(region))
    end

    sig { params(proc: T.proc.returns(T.untyped)).returns(T.self_type) }
    def indent(&proc)
      @indentation_level += 1
      proc.call
      @indentation_level -= 1
      self
    end

    sig { returns(T.self_type) }
    def print_indentation
      @indentation_level.times do
        print(INDENTATION)
      end
    end

    sig { params(x: T.untyped).returns(T.self_type) }
    def print(x)
      @out << x
      self
    end

    sig { returns(NameTable) }
    attr_reader :table
  end
end
