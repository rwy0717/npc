# typed: strict
# frozen_string_literal: true

module BF
  module IR
    class Program < NPC::Operation
      class << self
        extend T::Sig

        sig { returns(Program) }
        def build
          op = new(regions: [NPC::RegionKind::Exec])
          op.body_region.append_block!(NPC::Block.new)
          op
        end
      end

      extend T::Sig
      extend T::Helpers
      include NPC::NoTerminator

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
      class << self
        extend T::Sig

        sig { params(amount: Integer).returns(Inc) }
        def build(amount = 1)
          new(
            attributes: {
              amount: amount,
            }
          )
        end
      end

      include AmountAttribute
    end

    class Dec < NPC::Operation
      class << self
        extend T::Sig

        sig { params(amount: Integer).returns(Dec) }
        def build(amount = 1)
          super(
            attributes: {
              amount: amount,
            }
          )
        end
      end

      include AmountAttribute
    end

    class MoveL < NPC::Operation
      class << self
        extend T::Sig

        sig { params(amount: Integer).returns(MoveL) }
        def build(amount = 1)
          new(attributes: { amount: amount })
        end
      end

      include AmountAttribute
    end

    class MoveR < NPC::Operation
      class << self
        extend T::Sig

        sig { params(amount: Integer).returns(MoveR) }
        def build(amount = 1)
          new(attributes: { amount: amount })
        end
      end

      include AmountAttribute
    end

    class Print < NPC::Operation
      class << self
        extend T::Sig

        sig { returns(Print) }
        def build
          new
        end
      end
    end

    class Read < NPC::Operation
      class << self
        extend T::Sig

        sig { returns(Read) }
        def build
          new
        end
      end
    end

    class Loop < NPC::Operation
      class << self
        extend T::Sig

        sig { returns(Loop) }
        def build
          op = new(regions: [NPC::RegionKind::Exec])
          op.region(0).append_block!(NPC::Block.new)
          op
        end
      end

      extend T::Sig
      include NPC::OneRegion
      include NPC::NoTerminator

      sig { returns(NPC::Block) }
      def body
        region(0).first_block!
      end
    end

    # Extended IR

    class While < NPC::Operation
      class << self
        extend T::Sig

        sig { returns(While) }
        def build
          new(regions: [NPC::RegionKind::Exec])
        end
      end

      include NPC::OneRegion
    end

    class Add < NPC::Operation
      class << self
        extend T::Sig

        sig { returns(Add) }
        def build
          new
        end
      end
    end

    class Sub < NPC::Operation
      class << self
        extend T::Sig

        sig { returns(Sub) }
        def build
          new
        end
      end
    end

    class Store < NPC::Operation
      class << self
        extend T::Sig

        sig { returns(Store) }
        def build
          new
        end
      end
    end

    class Load < NPC::Operation
      class << self
        extend T::Sig

        sig { returns(Load) }
        def build
          new
        end
      end
    end

    class Move < NPC::Operation
      class << self
        extend T::Sig

        sig { returns(Move) }
        def build
          Move.new
        end
      end
    end
  end
end
