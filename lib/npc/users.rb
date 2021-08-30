# typed: strict
# frozen_string_literal: true

# require "npc/operator"

# module NPC
#   # An enumerable list of users.
#   # May report the same user multiple time, if the user has multiple uses.
#   # For example, an add op that uses the same constant twice.
#   class Users
#     extend T::Sig
#     extend T::Generic

#     include Enumerable

#     Elem = type_member(fixed: Operator)

#     prop :uses, Uses

#     sig { params(subject: Value).void }
#     def initialize(subject)
#       self.uses = subject.uses
#     end

#     sig do
#       params(
#         block: T.proc.params(
#           arg0: Operator,
#         ).returns(BasicObject)
#       ).returns(Users)
#     end
#     def each(&block)
#       uses.each do |use|
#         case use
#         when Operand
#           use.operation
#         end
#       end
#     end
#   end
# end
