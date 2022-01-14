# typed: strict
# frozen_string_literal: true

require("npc")

module Flow
  class HydrationSource < T::Struct
    const :url, String
  end

  class HydrationMethod
  end

  class GraphQLHydration < HydrationMethod
  end

  class HydrationSpec < T::Struct
    const :source, HydrationSource
    const :params, T::Array[Symbol]
    # const :request, T.untyped
  end

  # Hydrate data from a source
  class Hydrate < NPC::Operation
    extend T::Sig

    sig { params(spec: HydrationSpec).void }
    def initialize(spec)
      super()

      @spec = T.let(spec, HydrationSpec)
    end

    sig { returns(HydrationSpec) }
    attr_accessor :spec
  end
end
