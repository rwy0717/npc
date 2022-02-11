# typed: strict
# frozen_string_literal: true

require_relative("test")

class TestVerification < MiniTest::Test
  extend T::Sig

  focus
  sig { void }
  def test_simple
    m = NPC::Core::Module.new("example")
    f = NPC::Core::Function.new("test")
      .insert_into_block!(m.region(0).first_block!.back)
    r = f.region(0)
    b = r.first_block!

    x = NPC::Core::I32Add.new(nil, nil)
      .insert_into_block!(b.back)

    print(NPC::Verify.call(x).to_s)
  end
end
