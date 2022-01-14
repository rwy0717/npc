# typed: strict
# frozen_string_literal: true

require "npc/test"

# class TestPP < Minitest::Test
#   extend T::Sig
#
#   class MyThing < T::Struct
#     extend T::Sig
#     include NPC::PP::Formatable
#
#     const :name, String, default: "example"
#     const :value1, Integer, default: 1234
#     const :value2, T.nilable(MyThing), default: nil
#
#     def format(o)
#       o.lit(name)
#       # o.grp do |o|
#       #   o.txt(name)
#       #   o.lit(value1)
#       #   o.lit(value2)
#       # end
#     end
#   end
#
#   sig { void }
#   def test_pp
# #     literal = NPC::PP::Literal.new(1234)
# #     x = MyThing.new()
# #     f = NPC::PP.format(x)
#   end
# end
#
