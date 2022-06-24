# typed: strict
# frozen_string_literal: true

require("npc/type")

# require("npc/operation")

module NPC
  # A value that can be referenced or used within IR.
  class Value
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { params(type: T.nilable(Type), first_use: T.nilable(Operand)).void }
    def initialize(type, first_use = nil)
      @type      = T.let(type, T.nilable(Type))
      @first_use = T.let(first_use, T.nilable(Operand))
    end

    # Get this value's type.
    sig { returns(T.nilable(Type)) }
    attr_accessor :type

    sig { returns(Type) }
    def type!
      raise "no type" if @type.nil?

      @type
    end

    sig { returns(T.nilable(Operand)) }
    attr_accessor :first_use

    #
    # The first use of th
    sig { returns(Operand) }
    def first_use!
      T.must(@first_use)
    end

    # Does this have no uses?
    sig { returns(T::Boolean) }
    def unused?
      first_use.nil?
    end

    # Does this have any uses?
    sig { returns(T::Boolean) }
    def used?
      @first_use != nil
    end

    # Does this have exactly one use?
    sig { returns(T::Boolean) }
    def used_once?
      !@first_use.nil? && @first_use.next_use.nil?
    end

    sig { abstract.returns(T.nilable(Operation)) }
    def defining_operation; end

    # Get the block this value is defined in.
    sig { abstract.returns(T.nilable(Block)) }
    def defining_block; end

    # Get the region this value is defined in.
    sig { abstract.returns(T.nilable(Region)) }
    def defining_region; end

    # Are any users located in a different block than this?
    sig { returns(T::Boolean) }
    def used_outside_block?
      b = defining_block
      users.any? do |user|
        user.parent_block != b
      end
    end

    # An enumerable collection of all uses of this value.
    sig { returns(Uses) }
    def uses
      Uses.new(first_use)
    end

    sig { returns(Users) }
    def users
      Users.of(self)
    end

    # All uses as an array.
    sig { returns(T::Array[Operand]) }
    def uses_array
      uses.to_a
    end

    # Drop all uses. All uses of this value will be cleared.
    sig { void }
    def drop_uses!
      uses.each(&:unset!)
    end

    # Replace all uses of this value with a different value.
    sig { params(other: T.nilable(Value)).void }
    def replace_uses!(other)
      # TODO: Is it OK for other to be nilable?
      if other && (type != other.type)
        raise "cannot replaces the uses of a value with a value of a different type."
      end

      uses.each do |use|
        use.reset!(other)
      end
    end

    # Replace all uses of this value with another, unless the specific use is in the list of exceptions.
    sig do
      params(
        other: T.nilable(Value),
        exceptions: T::Array[Operand]
      ).void
    end
    def replace_uses_except!(other, exceptions)
      uses.each do |use|
        use.reset!(other) unless exceptions.include?(use)
      end
    end

    sig do
      params(
        other: T.nilable(Value),
        proc: T.proc.params(arg0: Operand).returns(T::Boolean),
      ).void
    end
    def replace_uses_if!(other, &proc)
      uses.each do |use|
        use.reset!(other) if proc.call(use)
      end
    end

    # Dump this use to a string.
    sig { returns(String) }
    def to_s
      "(value #{object_id}))"
    end
  end
end
