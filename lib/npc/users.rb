# typed: strict
# frozen_string_literal: true

module NPC
  ## An enumerable list of users.
  ## May report the same user multiple time, if the user has multiple uses.
  ## For example, an add op that uses the same constant twice.
  # class Users
  #   extend T::Generic
  #   include Base
  #   include Enumerable

  #   Elem = type_member(fixed: Operand)

  #   prop :uses, Uses

  #   sig { params(subject: Usable).void }
  #   def initialize(subject)
  #     self.uses = subject.uses
  #   end

  #   sig do
  #     params(
  #       block: T.proc.block(

  #       )
  #     )
  # end
end
