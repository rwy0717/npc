# typed: strict
# frozen_string_literal: true

module BF
  module IR
    class Program < NPC::Operation
      extend T::Sig
      extend T::Helpers
      # include NPC::NoResult
      include NPC::NoTerminator

      sig { void }
      def initialize
        super(regions: [NPC::RegionKind::Exec])
        body_region.append_block!(NPC::Block.new)
      end

      sig { returns(NPC::Region) }
      def body_region
        region(0)
      end

      sig { returns(NPC::Block) }
      def body
        body_region.first_block!
      end
    end

    module AmountAttribute
      extend T::Sig
      include NPC::OperationTrait

      sig { returns(Integer) }
      def amount
        T.cast(attribute(:amount), T.nilable(Integer)) || 1
      end

      sig { params(val: Integer).void }
      def amount=(val)
        set_attribute!(:amount, val)
      end
    end

    class Inc < NPC::Operation
      extend T::Sig
      include AmountAttribute

      sig { params(amount: Integer).void }
      def initialize(amount = 1)
        super(
          attributes: {
            amount: amount,
          }
        )
      end
    end

    class Dec < NPC::Operation
      extend T::Sig
      include AmountAttribute

      sig { params(amount: Integer).void }
      def initialize(amount = 1)
        super(
          attributes: {
            amount: amount,
          }
        )
      end
    end

    class MoveL < NPC::Operation
      extend T::Sig
      include AmountAttribute

      sig { params(amount: Integer).void }
      def initialize(amount = 1)
        super(
          attributes: {
            amount: amount,
          }
        )
      end
    end

    class MoveR < NPC::Operation
      extend T::Sig
      include AmountAttribute

      sig { params(amount: Integer).void }
      def initialize(amount = 1)
        super(attributes: { amount: amount })
      end
    end

    class Print < NPC::Operation; end

    class Read < NPC::Operation; end

    class Loop < NPC::Operation
      extend T::Sig
      include NPC::OneRegion
      include NPC::NoTerminator

      sig { void }
      def initialize
        super(regions: [NPC::RegionKind::Exec])
        region(0).append_block!(NPC::Block.new)
      end

      sig { returns(NPC::Block) }
      def body
        region(0).first_block!
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
