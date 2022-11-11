# typed: true
# frozen_string_literal: true

require "npc/test"

class TestFormat < Minitest::Test
  include NPC

  def test_1
    doc = Format.text("hello")
    assert_equal("hello", doc.to_s)
  end

  focus
  def test_2
    doc = Format.group(
      Format.concat(
        Format.text("hello"),
        Format.space,
        Format.text("world"),
      )
    )

    expected = <<~DOC
      hello
      world
    DOC

    assert_equal(expected, doc.to_s(width: Format::Finite(5)))
  end
end
