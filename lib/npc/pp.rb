# typed: strict
# frozen_string_literal: true

module NPC
  #   class << self
  #     # Pretty-print an object.
  #     sig { params(x: T.untyped).void }
  #     def pp(x)
  #       PP.write(PP.format(obj))
  #     end
  #   end
  #
  #   module PP
  #     extend T::Sig
  #     extend T::Helpers
  #
  #     class << self
  #       extend T::Sig
  #       extend T::Helpers
  #
  #       sig { params(x: T.untyped).returns(Node) }
  #       def format(x)
  #         if x.is_a?(Formatable)
  #           o = Output.new
  #           x.format(o)
  #           T.must(o.elements.first)
  #         else
  #           Literal.new(x)
  #         end
  #       end
  #
  #       sig { params(node: Node) }
  #       def write(node)
  #         binding.pry
  #       end
  #     end
  #
  #     class Config < T::Struct
  #       extend T::Sig
  #       const :r_margin, Integer
  #       const :l_margin, Integer
  #       const :indent,   Integer
  #     end
  #
  #     class State < T::Struct
  #       extend T::Sig
  #       prop :depth, Integer, default: 0
  #     end
  #
  #     module Formatable
  #       extend T::Sig
  #       extend T::Helpers
  #       abstract!
  #     end
  #
  #     # An element of an abstract document to be pretty printed.
  #     class Node
  #       extend T::Sig
  #       extend T::Helpers
  # #       abstract!
  # #
  # #       sig { abstract.params(state: State, config: Config).returns(String) }
  # #       def format(state, config); end
  # #
  # #       sig { abstract.returns(String) }
  # #       def to_s; end
  #     end
  #
  #     # An object literal.
  #     class Literal < Node
  #       extend T::Sig
  #
  #       sig { params(value: T.untyped).void }
  #       def initialize(value)
  #         @value = T.let(value, T.untyped)
  #       end
  #
  #       sig { returns(T.any) }
  #       attr_accessor :value
  #
  #       sig { override.returns(String) }
  #       def to_s
  #         "(literal #{value})"
  #       end
  #     end
  #
  #     # Text printed verbatim.
  #     class Text < Node
  #       extend T::Sig
  #
  #       sig { params(value: String).void }
  #       def initialize(value)
  #         super()
  #         @value = T.let(value, String)
  #       end
  #
  #       sig { returns(String) }
  #       attr_accessor :value
  #
  #       sig { override.returns(String) }
  #       def to_s
  #         "(text \"#{@text}\")"
  #       end
  #     end
  #
  #     LPAREN = Text.new("(")
  #     RPAREN = Text.new(")")
  #
  #     class Group < Node
  #       extend T::Sig
  #
  #       sig { params(elements: T::Array[Node]).void }
  #       def initialize(elements = [])
  #         super()
  #         @elements = T.let(elements, T::Array[Node])
  #       end
  #
  #       sig { returns(T::Array[Node]) }
  #       attr_accessor :elements
  #
  #       # sig { override.returns(String) }
  #     end
  #
  #     class Span < Node
  #       extend T::Sig
  #     end
  #
  #     sig { params(node: Node).returns(String) }
  #     def render(node)
  #       case node
  #       when Literal
  #         node.value.to_s
  #       when Text
  #       when Group
  #       end
  #     end
  #
  #     # Accumulator for output
  #     class Output
  #       extend T::Sig
  #
  #       sig { void }
  #       def initialize
  #         @elements = T.let([], T::Array[Node])
  #       end
  #
  #       sig { params(object: T.untyped).returns(Output) }
  #       def lit(object)
  #          @elements << Literal.new(object)
  #          self
  #       end
  #
  #       sig { params(string: String).returns(Output) }
  #       def txt(string)
  #         @elements << Text.new(string)
  #         self
  #       end
  #
  #       sig { params(proc: T.proc(arg0: Output).void).returns(Output) }
  #       def grp(&proc)
  #         out = Output.new
  #         proc.call(out)
  #         @elements << out
  #         self
  #       end
  #     end
  #
  #     def write(out)
  #       state = State.new
  #       elements(x)
  #     end
  #   end

  # class PP
  #   class << self
  #     extend T::Sig

  #     sig { params(x: T.untyped).returns(void) }
  #     def print(x)
  #       PP.new.print(x)
  #     end
  #   end

  #   extend T::Sig

  #   # Generic printing utility.
  #   sig { params(x: T.untyped).returns(void) }
  #   def print(x)
  #     if x.is_a?(PP::Printable)
  #       x.pp(self)
  #     else
  #       pp(x)
  #     end
  #   end
  # end
end
