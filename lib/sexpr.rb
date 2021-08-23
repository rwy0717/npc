# typed: true
# frozen_string_literal: true

module Sexpr
  extend T::Sig
  extend T::Helpers
  include Kernel

  abstract!

  sig { returns(String) }
  def to_s
    to_str
  end

  sig { returns(String) }
  def to_str
    "(" + sexpr_terms.join(" ") + ")"
  end

  sig { void }
  def pp
    puts to_str
  end

  sig { abstract.returns(Array) }
  def sexpr_terms; end
end
