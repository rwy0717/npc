# typed: strict
# frozen_string_literal: true

module NPC
  # A use of a value. Uses are arranged into a linked-list.
  class Use
    include Base

    sig { params(value: T.nilable(Value)).void }
    def initialize(value = nil)
      @prev_use = T.let(nil, T.nilable(Use))
      @next_use = T.let(nil, T.nilable(Use))
      @value    = T.let(nil, T.nilable(Value))
      use(value) if value
    end

    # The value of this operand.
    sig { returns(T.nilable(Value)) }
    attr_reader :value

    # The value of this operand. Throws if value is nil.
    sig { returns(Value) }
    def value!
      T.must(value)
    end

    # Point this use at a new value, or clear this use by assigning nil.
    sig do
      params(
        value: T.nilable(Value)
      ).returns(T.nilable(Value))
    end
    def value=(value)
      clear
      use(value) if value
      value
    end

    # True if this use points at a value.
    sig { returns(T::Boolean) }
    def value?
      value != nil
    end

    # Clear this usage, removing this value.
    sig { void }
    def clear
      drop if value?
    end

    sig { returns(T.nilable(Use)) }
    attr_accessor :prev_use

    sig { returns(T.nilable(Use)) }
    attr_accessor :next_use

    private

    sig { params(value: Value).void }
    def use(value)
      insert_into(value.uses)
      @value = value
    end

    sig { params(list: Uses).void }
    def insert_into(list)
      self.prev_use = nil
      self.next_use = list.first
      n = next_use
      n.prev_use = self if n
    end

    # Remove this usage and clear.
    sig { void }
    def drop
      p = prev_use
      n = next_use
      p.next_use = n if p
      n.prev_use = p if n
      self.prev_use = nil
      self.next_use = nil
      @value = nil
    end
  end
end
