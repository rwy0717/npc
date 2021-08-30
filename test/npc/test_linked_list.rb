# typed: strict
# frozen_string_literal: true

require "npc/test"

# class Link < T::Struct
#   extend T::Sig
#   require NPC::Linked

#   const :link_prev, T.any(Linked, Sentinel, NilClass))
# end

# class List < NPC::LinkedList
#   Elem = T.type_member(fixed: Link)
# end

# class TestLinkedList < Minitest::Test
#   extend T::Sig

#   sig { void }
#   def test_link

#     list = List.new
#     link = Link.new(into )
#     value = NPC::Value.new
#     use1 = NPC::Use.new(value)
#     use2 = NPC::Use.new(value)
#     use3 = NPC::Use.new(value)
#     assert_equal([use3, use2, use1], value.uses.to_a)
#   end
# end
