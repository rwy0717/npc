# typed: false
# frozen_string_literal: true

module NPC
  # A special type of pass that writes out, or reads in, the IR of a program.
  module Translation
    extend T::Sig
    extend T::Helpers
  end

  # A translation that reads in the IR of a program from some external format.
  module Importer
    extend T::Sig
    extend T::Helpers
    include Translation
    interface!

    sig { abstract.returns(Operation) }
    def import; end
  end

  # A translation that write out the IR of a program to some external format.
  # An exporter is a kind of pass that is:
  # 1. not allowed to mutate the IR
  # 2. not allowed to invalidate any analysis results.
  module Exporter
    extend T::Sig
    extend T::Helpers
    include Translation
    include NPC::Pass
    abstract!

    sig(:final) { override.params(_context: PassContext, target: Operation).returns(PassResult) }
    def run(_context, target)
      export(target)
      PassResult::Success.new(Preservation::All.new)
    end

    sig { abstract.params(operation: Operation).void }
    def export(operation); end
  end
end
