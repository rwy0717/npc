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

      return unless value

      @next_use = value.first_use
      @next_use.prev_use = self if @next_use
      value.first_use = self
      self.value = value
    end

    # The value this is using.
    sig { returns(T.nilable(Value)) }
    attr_reader :value

    # The value this is using. Throws if value is nil.
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
      drop
      return nil unless value
      @next_use = value.first_use
      @next_use.prev_use = self if @next_use
      value.first_use = self
      @value = value
    end

    # True if this use points at a value.
    sig { returns(T::Boolean) }
    def value?
      @value != nil
    end

    # Clear this use. The value is cleared, and this use is removed from the value's use-list.
    sig { void }
    def drop
      return if @value.nil?
      @prev_use.next_use = @next_use if @prev_use
      @next_use.prev_use = @prev_use if @next_use
      @prev_use = nil
      @next_use = nil
      @value = nil
    end

    sig { returns(T.nilable(Use)) }
    attr_accessor :prev_use

    sig { returns(T.nilable(Use)) }
    attr_accessor :next_use
  end
end
