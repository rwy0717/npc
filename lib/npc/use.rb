# typed: strict
# frozen_string_literal: true

module NPC
  # A use of a value. Uses are arranged into a linked-list.
  class Use
    extend T::Sig

    sig { params(value: T.nilable(Value)).void.checked(:never) }
    def initialize(value = nil)
      @value = T.let(value, T.nilable(Value))
      @prev_use = T.let(nil, T.nilable(Use))
      @next_use = T.let(nil, T.nilable(Use))

      if value
        first = value.first_use
        value.first_use = self
        if first
          @next_use = first
          first.prev_use = self
        end
      end
    end

    # The value this is using.
    sig { returns(T.nilable(Value)) }
    attr_reader :value

    # The value this is using. Throws if value is nil.
    sig { returns(Value) }
    def value!
      T.must(value)
    end

    # True if this use points at a value.
    sig { returns(T::Boolean) }
    def value?
      @value != nil
    end

    sig { returns(T.nilable(Use)) }
    attr_accessor :prev_use

    sig { returns(T.nilable(Use)) }
    attr_accessor :next_use

    # Attach this usage to a value.
    sig { params(value: Value).void }
    def insert_into_value!(value)
      raise "use already attached to value" unless @value.nil?

      @next_use = value.first_use
      @next_use.prev_use = self if @next_use
      value.first_use = self
    end

    # Remove this usage from it's value.
    sig { void }
    def remove_from_value!
      raise "use not attached to value" unless @value != nil

      if @value.first_use == self
        @value.first_use = @next_use
      end

      @prev_use.next_use = @next_use if @prev_use
      @next_use.prev_use = @prev_use if @next_use

      @value = nil
      @prev_use = nil
      @next_use = nil
    end

    # Reset this use to target a new value.
    sig { params(value: T.nilable(Value)).void }
    def value=(value)
      remove_from_value! if value?
      insert_into_value!(value) if value
    end

    # Clear this use.
    sig { void }
    def drop!
      remove_from_value! if value?
    end
  end
end
