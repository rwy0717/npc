# typed: strict
# frozen_string_literal: true

module NPC
  # tracing support in NPC.
  # TODO: should be compatible with OpenTelemetry.
  # module Trace
  #   extend T::Sig
  #   extend T::Helpers
  #   abstract!

  #   # Append a sub-trace to this entry.
  #   sig { abstract.params(entry: Trace).returns(T.self_type) }
  #   def <<(entry); end
  # end

  # module TraceHelpers
  #   extend T::Sig

  #   sig { params(level: Integer).returns(String) }
  #   def indent(level)
  #     "  " * level
  #   end
  # end

  # # Record of a pass that was run.
  # class PassTrace
  #   extend T::Sig
  #   include Trace

  #   # Duration in seconds.
  #   sig { params(duration: Number, pass: Pass, target: Operation).void }
  #   def initialize(duration, pass, target)
  #     @pass       = T.let(pass, Pass)
  #     @target     = T.let(target, Operation)
  #     @subentries = T.let([], T::Array[TraceEntry])
  #   end

  #   sig { returns(T::Array[TraceEntry]) }
  #   attr_reader :entries

  #   sig { params(level: Number).returns(String) }
  #   def format(level)
  #     msg = "#{pass.class.name} (#{duration})"
  #     subentries.each do |entry|
  #       msg += "\n"
  #       msg += entry.format(level + 1)
  #     end
  #     msg
  #   end

  #   def to_s
  #   end
  # end

  # # The root trace entry.
  # class RootTrace
  #   extend T::Sig

  #   # Construct the root trace.
  #   # duration is in seconds.
  #   sig { params(duration: Number, entries: T::Array[Entry]).void }
  #   def initialize(duration, entries)
  #     @duration = T.let(duration, Float)
  #     @entries  = T.let([], T::Array[TraceEntry])
  #   end

  #   sig { void }
  #   def dump
  #     $stdout.print(to_s)
  #   end

  #   sig { params(level: Integer).returns(String) }
  #   def format(level = 0)
  #     msg = "root: #{duration}"
  #     entries.each do |entry|
  #       msg += "\n"
  #       msg += entry.format(level + 1)
  #     end
  #     msg
  #   end

  #   sig { returns(String) }
  #   def to_s
  #     format(0)
  #   end
  # end
end
