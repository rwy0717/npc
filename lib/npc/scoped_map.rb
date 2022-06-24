# typed: strict
# frozen_string_literal: true

module NPC
  # TODO: rename to scoped hash?
  class ScopedMap
    extend T::Sig
    extend T::Helpers
    extend T::Generic

    Key = type_member
    Val = type_member

    sig { void }
    def initialize
      @stack = T.let([{}], T::Array[T::Hash[Key, Val]])
    end

    sig { returns(T::Array[T::Hash[Key, Val]]) }
    attr_reader :stack

    sig { returns(T.nilable(T::Hash[Key, Val])) }
    def scope
      @stack.last
    end

    sig { returns(T::Hash[Key, Val]) }
    def scope!
      T.must(@stack.last)
    end

    sig { params(scope: T::Hash[Key, Val]).void }
    def enter!(scope = {})
      @stack.push(scope)
    end

    sig { void }
    def leave!
      @stack.pop
    end

    sig { params(key: Key).returns(T.nilable(Val)) }
    def [](key)
      @stack.each do |scope|
        return scope.fetch(key) if scope.key?(key)
      end
      nil
    end

    sig { params(key: Key, val: Val).returns(Val) }
    def []=(key, val)
      scope![key] = val
    end

    sig { params(key: Key).returns(T::Boolean) }
    def key?(key)
      @stack.any? { |scope| scope.key?(key) }
    end

    sig { params(key: Key).returns(Val) }
    def fetch(key)
      @stack.each do |scope|
        return scope.fetch(key) if scope.key?(key)
      end
      raise "No such key: #{key}"
    end
  end
end
