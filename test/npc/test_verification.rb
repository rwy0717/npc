# typed: strict
# frozen_string_literal: true

require_relative("test")

class TestVerification < MiniTest::Test
  extend T::Sig

  sig { void }
  def test_simple
    m = NPC::ExIR::Module.build
    f = NPC::ExIR::Function.build
      .insert_into_block!(m.region(0).first_block!.back)
    r = f.region(0)
    b = r.first_block!

    x = NPC::ExIR::Add.build(nil, nil)
      .insert_into_block!(b.back)

    print(NPC::Verify.call(x).to_s)
  end

  sig { void }
  def test_bad_cfg
    m = NPC::ExIR::Module.build
    f = NPC::ExIR::Function.build
      .insert_into_block!(m.region(0).first_block!.back)
    r = f.region(0)
    b = r.first_block!

    x = NPC::ExIR::Add.build(nil, nil)
      .insert_into_block!(b.back)

    print(NPC::Verify.call(x).to_s)
  end
end
