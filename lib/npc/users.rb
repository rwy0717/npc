# typed: strict
# frozen_string_literal: true

# require "npc/operator"

module NPC
  # An adapter for iterating the users of a value.
  class Users
    class << self
      extend T::Sig

      sig { params(value: Value).returns(Users) }
      def of(value)
        Users.new(value.first_use)
      end
    end

    extend T::Sig
    extend T::Generic
    include Enumerable

    Elem = type_member { { fixed: Operation } }

    sig { params(use: T.nilable(Operand)).void }
    def initialize(use)
      @use = T.let(use, T.nilable(Operand))
    end

    sig do
      override.params(
          proc: T.proc.params(arg0: Operation).void
        ).returns(Users)
    end
    def each(&proc)
      Uses.new(@use).each do |use|
        proc.call(use.owning_operation)
      end
      self
    end
  end
end
