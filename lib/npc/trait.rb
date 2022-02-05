# typed: strict
# frozen_string_literal: true

module NPC
  # A mixin for operators definitions.
  module Trait
    extend T::Sig

    class << self
      extend T::Sig
    end
  end

  # A trait that can be implemented by a dialect.
  module DialectTrait
  end

  # A trait that can be implemented by an operation.
  module OperationTrait
    extend T::Sig
    extend T::Helpers
    include Trait

    abstract!

    class << self
      extend T::Sig
    end
  end
end
