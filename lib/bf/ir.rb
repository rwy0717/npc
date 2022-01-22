# typed: strict
# frozen_string_literal: true

module BF
  module IR
    # Base IR

    class Operation < NPC::Operation; end

    class Program < NPC::NullaryOperation
      extend T::Sig
      extend T::Helpers
      include NPC::NoResult

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

    class Inc < NPC::NullaryOperation
      include NPC::NoResult

      sig { void }
      def initialize
        super()
      end
    end

    class Dec < Operation; end

    class MoveL < Operation; end

    class MoveR < Operation; end

    class LoopL < Operation; end

    class LoopR < Operation; end

    class Print < Operation; end

    # Extended IR

    class While < NPC::Operation
      extend T::Sig

      include NPC::OneRegion

      sig { void }
      def initialize
        super(regions: 1)
      end
    end

    class Add < Operation; end

    class Sub < Operation; end

    class Store < Operation; end

    class Load < Operation; end

    class Move < Operation; end
  end
end
