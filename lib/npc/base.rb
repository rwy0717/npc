# typed: strict
# frozen_string_literal: true

require("sorbet-runtime")

module NPC
  module Base
    extend T::Sig
    extend T::Helpers

    include T::Props::Constructor

    module ClassMethods
      include T::Sig
      include T::Helpers
      include T::Props::ClassMethods
    end

    mixes_in_class_methods ClassMethods
  end
end
