# typed: strict
# frozen_string_literal: true

# require "npc/operator"

module NPC
  # An adapter for iterating the users of a value.
  class Users
    extend T::Sig
    extend T::Generic
    include Enumerable

    Elem = type_member(fixed: Operation)

    class << self
      extend T::Sig

      sig { params(value: Value).returns(Users) }
      def of(value)
        Users.new(value.first_use)
      end
    end

    sig { params(use: T.nilable(Use)).void }
    def initialize(use)
      @use = T.let(use, T.nilable(Use))
    end

    sig do
      override.params(
          proc: T.proc.params(arg0: Operation).void
        ).returns(Users)
    end
    def each(&proc)
      Uses.new(@use).each do |use|
        case use
        when Operand
          proc.call(use.operation)
        end
      end
      self
    end
  end
end
