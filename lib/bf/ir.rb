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

    class LoopL < BaseOp; end

    class LoopR < BaseOp; end

    class Print < BaseOp; end

    class Add < BaseOp; end

    class Sub < BaseOp; end

    class Store < BaseOp; end

    class Load < BaseOp; end

    class Move < BaseOp; end
  end
end
