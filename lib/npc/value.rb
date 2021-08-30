# typed: strict
# frozen_string_literal: true

require("npc/base")
# require("npc/operation")

module NPC
  # A value that can be referenced or used within IR.
  class Value
    extend T::Sig

    sig { params(first_use: T.nilable(Use)).void }
    def initialize(first_use = nil)
      @first_use = T.let(first_use, T.nilable(Use))
    end

    sig { returns(T.nilable(Use)) }
    attr_accessor :first_use

    # If this is the result of an operation, get that operation.
    sig { returns(T.nilable(Operation)) }
    def defining_operation
      nil
    end

    # Does this have no uses?
    sig { returns(T::Boolean) }
    def unused?
      first_use.nil?
    end

    # Does this have any uses?
    sig { returns(T::Boolean) }
    def used?
      first_use != nil
    end

    # Does this have exactly one use?
    sig { returns(T::Boolean) }
    def used_once?
      use = first_use
      if use
        use.next_use.nil?
      else
        false
      end
    end

    # An enumerable collection of all uses of this value.
    sig { returns(Uses) }
    def uses
      Uses.new(first_use)
    end

    # All uses as an array.
    sig { returns(T::Array[Use]) }
    def uses_a
      uses.to_a
    end

    # Drop all uses. All uses of this value will be cleared.
    sig { void }
    def drop_uses!
      uses.each(&:remove_from_value!)
    end

    # Replace all uses of this value with a different value.
    sig { params(other: T.nilable(Value)).void }
    def replace_uses!(other)
      uses.each do |use|
        use.value = other
      end
    end

    sig { returns(String) }
    def to_s
      "(value #{object_id}))"
    end
  end
end
