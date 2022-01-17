# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class Return < Operation
      extend T::Sig
      include Terminator

      sig { params(result: Value).void }
      def initialize(result)
        super()
        new_operand(result)
      end
    end
  end
end
