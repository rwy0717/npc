# typed: strict
# frozen_string_literal: true

module NPC
  module WASM
    class FuncTypeTable
      extend T::Sig

      sig { void }
      def initialize
        @index_table = T.let({}, T::Hash[IR::FuncType, Integer])
        @types = T.let([], T::Array[IR::FuncType])
      end

      sig { params(type: T.any(IR::FuncType, Integer)).returns(Integer) }
      def intern(type)
        # type is already an integer
        if type.is_a?(Integer)
          return type
        end

        # type is already interned
        index = @index_table[type]
        return index if index

        # type must be interned
        type = type.frozen? ? type : type.dup.freeze
        index = @index_table.size
        @index_table[type] = index
        @types << type
        index
      end

      sig { params(type: IR::FuncType).returns(T::Boolean) }
      def interned?(type)
        @index_table.key?(type)
      end

      sig { params(block: T.nilable(T.proc.params(x: IR::FuncType).void)).void }
      def each(&block)
        if block_given?
          @types.each(&block)
        else
          @types.each
        end
      end

      sig { params(block: T.nilable(T.proc.params(x: IR::FuncType, i: Integer).void)).void }
      def each_with_index(&block)
        if block_given?
          @types.each_with_index(&block)
        else
          @types.each_with_index
        end
      end

      sig { params(index: Integer).returns(T.nilable(IR::FuncType)) }
      def [](index)
        @types[index]
      end

      sig { returns(Integer) }
      def length
        @types.length
      end

      sig { returns(T::Boolean) }
      def empty?
        @types.empty?
      end

      sig { returns(T::Array[IR::FuncType]) }
      attr_reader :types
    end
  end
end
