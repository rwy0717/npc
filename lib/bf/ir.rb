# typed: strict
# frozen_string_literal: true
module BF
  module IR
    # Base IR

    class BaseOp < NPC::Op
      include NPC::Base

      sig do
        params(
          location: NPC::Location
        ).void
      end
      def initialize(location)
        super(
          location: location,
          operands: [],
          results: [],
        )
      end
    end

    class Inc < BaseOp; end
    class Dec < BaseOp; end
    class MoveL < BaseOp; end
    class MoveR < BaseOp; end
    class Print < BaseOp; end
  end
end
