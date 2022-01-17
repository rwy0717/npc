# typed: strict
# frozen_string_literal: true

module NPC
  # An adapter for iterating the uses of a value.
  class Uses
    class << self
      extend T::Sig

      # The uses of a value
      sig { params(value: Value).returns(Uses) }
      def of(value)
        Uses.new(value.first_use)
      end
    end

    extend T::Sig
    extend T::Generic
    include Enumerable

    Elem = type_member(fixed: Operand)

    sig { params(use: T.nilable(Operand)).void }
    def initialize(use = nil)
      @use = T.let(use, T.nilable(Operand))
    end

    sig { params(use: T.nilable(Operand)).void }
    def reset(use)
      @use = use
    end

    sig do
      override
        .params(proc: T.proc.params(arg0: Operand).void)
        .returns(Uses)
    end
    def each(&proc)
      use = T.let(@use, T.nilable(Operand))
      while use
        n = use.next_use
        proc.call(use)
        use = n
      end
      self
    end
  end
end
