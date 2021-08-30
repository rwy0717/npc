# typed: strict
# frozen_string_literal: true

# require "npc/linked"

# module NPC
#   # Interface for objects in an intrusive linked list.
#   module Linked
#     extend T::Sig

#     sig { abstract.returns(T.any(Linked, Sentinel, NilClass)) }
#     def link_prev; end

#     sig { abstract.params(link: T.any(Linked, Sentinel, NilClass)).void }
#     def link_prev=(link); end

#     sig { abstract.returns(T.any(Linked, Sentinel, NilClass)) }
#     def link_next; end

#     sig { abstract.params(link: T.any(Linked, Sentinel, NilClass)).void }
#     def link_next=(link); end

#     sig { params(p: T.returns(T.nilable(T.self_type)) }
#     def prev
#       to_self_type(_link_prev)
#     end

#     sig { returns(T.nilable(T.self_type)) }
#     def next
#       to_self_type(_link_next)
#     end

#     sig { returns(T.self_type) }
#     def prev!
#       T.must(link_prev)
#     end

#     sig { returns(T.self_type) }
#     def next!
#       T.must(link_next)
#     end

#     private

#     # Convert X to this type, if it is one. Otherwise, return nil.
#     sig { params(x: T.untyped).returns(T.nilable(T.self_type)) }
#     def to_self_type(x)
#       x if x && x.is_a?(T.self_type) else nil
#     end
#   end

#   class LinkedList
#     extend T::Sig
#     extend T::Generic

#     abstract!

#     Elem = type_member

#     sig { void }
#     def initialize
#       @sentinel = T.let(LinkedSentinel.new, LinkedSentinel)
#     end
#   end
# end
