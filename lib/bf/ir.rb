# typed: strict
# frozen_string_literal: true

module BF
  module IR
    class Program < NPC::Operation
      extend T::Sig
      extend T::Helpers
      # include NPC::NoResult

      sig { void }
      def initialize
        super()
        @body = T.let(NPC::Region.new, NPC::Region)
      end

      sig { returns(T::Array[NPC::Result]) }
      attr_reader :results

      sig { returns(NPC::Region) }
      attr_reader :body
    end

    class Inc < NPC::Operation; end

    class Dec < NPC::Operation; end

    class MoveL < NPC::Operation; end

    class MoveR < NPC::Operation; end

    class LoopL < NPC::Operation; end

    class LoopR < NPC::Operation; end

    class Print < NPC::Operation; end

    class Read < NPC::Operation; end

    class Loop < NPC::Operation
      extend T::Sig
      include NPC::OneRegion

      sig { void }
      def initialize
        super(
          operands
        )
      end
    end

    # Extended IR

    class While < NPC::Operation
      extend T::Sig

      include NPC::OneRegion

      sig { void }
      def initialize
        super(regions: 1)
      end
    end

    class Add < NPC::Operation; end

    class Sub < NPC::Operation; end

    class Store < NPC::Operation; end

    class Load < NPC::Operation; end

    class Move < NPC::Operation; end
  end
end
