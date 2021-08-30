# typed: strict
# frozen_string_literal: true
module BF
  module IR
    # Base IR

    class Operation < NPC::Operation; end

    class Inc < Operation; end

    class Dec < Operation; end

    class MoveL < Operation; end

    class MoveR < Operation; end

    class LoopL < Operation; end

    class LoopR < Operation; end

    class Print < Operation; end

    class Add < Operation; end

    class Sub < Operation; end

    class Store < Operation; end

    class Load < Operation; end

    class Move < Operation; end
  end
end
