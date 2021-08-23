# typed: strict
# frozen_string_literal: true

module NPC
  ## A sequence of uses of an IR entity.
  class Uses
    extend T::Generic
    include Base
    include Enumerable

    Elem = type_member(fixed: Use)

    prop :next_use, T.nilable(Use), default: nil

    sig { params(value: Value).void }
    def initialize(value)
      @next_use = T.let(value.first_use, T.nilable(Use))
    end

    sig do
      override
        .params(block: T.proc.params(arg0: Elem).returns(BasicObject))
        .returns(T.untyped)
    end
    def each(&block)
      use = T.let(first, T.nilable(Use))
      while use
        next_use = use.next_use
        block.call(use)
        use = next_use
      end
    end

    sig { void }
    def clear_all_uses
      each(&:clear)
    end
  end
end
