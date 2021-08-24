# typed: strict
# frozen_string_literal: true

module NPC
  # An adapter for iterating the uses of a value.
  class Uses
    extend T::Sig
    extend T::Generic
    include Enumerable

    Elem = type_member(fixed: Use)

    sig { params(head: T.nilable(Use)).void }
    def initialize(head)
      @head = T.let(head, T.nilable(Use))
    end

    sig do
      override
        .params(blk: T.proc.params(arg0: Use).void)
        .returns(Uses)
    end
    def each(&blk)
      head = T.let(head, T.nilable(Use))
      while head
        tail = head.next_use
        blk.call(head)
        head = tail
      end
      self
    end
  end
end
