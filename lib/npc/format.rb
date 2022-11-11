# typed: strict
# frozen_string_literal: true

module NPC
  module Format
    Output = T.type_alias { T.any(StringIO, IO) }

    module Width
      extend T::Sig
      extend T::Helpers
      include Kernel
      include Comparable
      abstract!
      sealed!

      sig { abstract.params(rhs: Width).returns(Width) }
      def +(other); end

      sig { abstract.params(rhs: Width).returns(Integer) }
      def <=>(other); end
    end

    class Infinite
      extend T::Sig
      extend T::Helpers
      include Width
      include Singleton
      final!

      sig(:final) { override.params(rhs: Width).returns(Width) }
      def +(other)
        self
      end

      sig(:final) { override.params(rhs: Width).returns(Integer) }
      def <=>(rhs)
        case r
        when Finite
          1
        when Infinite
          0
        end
      end
    end

    INFINITE = T.let(Infinite.instance, Infinite)

    class Finite
      extend T::Sig
      extend T::Helpers
      include Width

      sig { params(n: Integer).void }
      def initialize(n)
        @value = T.let(n, Integer)
      end

      sig { returns(Integer) }
      attr_reader :value

      sig { params(rhs: Width).returns(Width) }
      def +(rhs)
        case rhs
        when Finite
          Finite.new(@value + rhs.value)
        when Infinite
          INFINITE
        end
      end

      sig { params(rhs: Width).returns(T::Boolean) }
      def <=(rhs)
        case rhs
        when Finite
          @value <=> rhs.value
        when Infinite
          -1
        end
      end
    end

    DEFAULT_WIDTH = T.let(Finite.new(80), Width)

    class RenderState < T::Struct
      extend T::Sig

      # Configuration

      const :width,  Width,  default: DEFAULT_WIDTH
      const :output, Output, default: $stdout
      const :depth,  Integer, default: 0
      # State

      # The current column we have printed to.
      prop :column,   Integer,    default: 0

      sig { params(string: String).void }
      def write!(string)

        write_indentation if column == 0
        output.write(string)
        column += string.length
      end

      sig { void }
      def write_br
        output.write("\n")
        column = 0
      end


    end

    class Mode < T::Enum
      enums do
        # Printing in a single-line format
        Flat = new

        # Printing in a multi-line format
        Normal = new
      end
    end

    module Document
      class << self
        extend T::Sig

        sig { params(string: String).returns(Document) }
        def from_string(string)
          raise "TODO: unimplemented"
        end
      end

      extend T::Sig
      extend T::Helpers
      abstract!

      # The required horizontal width, if this document was printed on a single line.
      sig { abstract.returns(Width) }
      def width; end

      # Internal API. Print this document.
      sig { abstract.params(state: RenderState, mode: Mode, depth: Integer).void }
      def render(state, mode, depth); end

      sig { params(output: Output, width: Width).void }
      def write(output = $stdout, width = DEFAULT_WIDTH)
        render(
          State.new(
            width:  width,
            output: output,
          ),
          Mode::Normal,
          0,
        )
      end

      sig { returns(String) }
      def to_s(width = DEFAULT_WIDTH)
        buffer = StringIO.new
        write(buffer)
        buffer.string
      end
    end

    #
    # Core Document Elements
    #

    # An empty document.
    class Empty
      extend T::Sig
      extend T::Helpers
      include Document
      final!

      sig(:final) { override.returns(Width) }
      def width
        Finite.new(0)
      end

      sig(:final) { override.params(state: State, mode: Mode, depth: Integer).void }
      def render(state, mode, depth); end
    end

    # A literal string of output.
    # The string must not contain any control characters, newlines, or tabs.
    class Text
      extend T::Sig
      extend T::Helpers
      include Document
      final!

      sig(:final) { params(text: String).void }
      def initialize(text)
        @text = T.let(text, String)
      end

      sig(:final) { returns(String) }
      attr_reader :text

      sig(:final) { override.returns(Width) }
      def width
        Finite.new(string.length)
      end

      sig(:final) { override.params(state: State, mode: Mode, depth: Integer).void }
      def render(state, mode, depth)
        if state.column == 0

        output.write(@text)
        state.column += @text.length
      end
    end

    # A space in the output, or a newline if the width is exceeded.
    class Space
      extend T::Sig
      extend T::Helpers
      include Document
      final!

      sig(:final) { params(length: Integer).void }
      def initialize(length)
        @length = T.let(length, Integer)
      end

      sig(:final) { override.returns(Width) }
      def width
        Finite.new(1)
      end

      sig(:final) do
        override.params(
          state:        State,
          indent_level: Integer,
          flatten:      T::Boolean,
          output:       Output,
        )
      end
      def render(state:, indent_level:, flatten:, output:)
        if flatten
          state.output.write(" " * depth) if 
          state.output.write(" " * length)
          state.column += length
        else
          output.write("\n" 
        end
      end
    end

    # A hard linebreak in the output.
    # Subsequent output will be indented to the current indentation level.
    class Break
      extend T::Sig
      extend T::Helpers
      include Document
      final!

      sig(:final) { override.returns(Width) }
      def width
        INFINITY
      end

      sig(:final) do
        params(
          state:        State, mode: Mode, depth: Integer,
        ).void
      end
      def render(state, mode, depth)
        state.output.write("\n")
        state.column = 0
      end
    end

    # The concatenation of two or more documents.
    class Concat
      extend T::Sig
      extend T::Helpers
      include Document
      final!

      sig(:final) { params(documents: T::Array[Document]).void }
      def initialize(*documents)
        @documents = T.let(documents, T::Array[Document])
      end

      sig(:final) { override.returns(Width) }
      def width
        documents.reduce(Finite.new(0)) do |width, document|
          width + document.width
        end
      end

      sig(:final) do
        override.params(
          state:        State,
          indent_level: Integer,
          flatten:      T::Boolean,
          output:       Output,
        ).void
      end
      def render(state:, indent_level:, flatten:, output:)
        @documents.each do |document|
          document.render(
            state:        state,
            indent_level: indent_level,
            flatten:      flatten,
            output:       output,
          )
        end
      end
    end

    class IfFlat
      extend T::Sig
      extend T::Helpers
      include Document
      final!

      sig(:final) { params(then_doc: Document, else_doc: Document).void }
      def initialize(then_doc, else_doc)
        raise "cannot nest if-flat in left side of branch" if then_doc.is_a?(IfFlat)

        @then_doc = T.let(then_doc, Document)
        @else_doc = T.let(else_doc, Document)
      end

      sig(:final) { returns(Document) }
      attr_reader :then_doc

      sig(:final) { returns(Document) }
      attr_reader :else_doc

      sig(:final) { override.returns(Width) }
      def width
        then_doc.width
      end

      sig(:final) do
        override.params(
          state:        State,
          indent_level: Integer,
          flatten:      T::Boolean,
          output:       Output,
        ).void
      end
      def render(state:, indent_level:, flatten:, output:)
        if flatten
          @then_doc.render(state: state, indent_level: indent_level, flatten: true, output: output)
        else
          @else_doc.render(state: state, indent_level: indent_level, flatten: true, output: output)
        end
      end
    end

    # Everything within a group is either flattened or indented.
    class Group
      extend T::Sig
      extend T::Helpers
      include Document
      final!

      sig(:final) { params(documents: T::Array[Document]).void }
      def initialize(*documents)
      end

      sig(:final) { override.returns(Width) }
      def width
      end

      sig(:final) do
        override.params(
          state:        State,
          indent_level: Integer,
          flatten:      T::Boolean,
          output:       Output,
        ).void
      end
      def render(state:, indent_level:, flatten:, output:)

        if Finite.new(80) <= width 
          
      end
    end

    # A control sequence. It's assumed it's width is zero, no change to rendered output.
    class Control
    end

    class << self
      extend T::Sig

      sig { params(string: String).returns(Text) }
      def text(string)
        Text.new(string)
      end

      sig { returns(Space) }
      def space
        Space.new
      end
    end
  end
end

# module Print

#     module Doc
#       # A printable element.
#       module Element
#         extend T::Sig
#         extend T::Helpers
#         include Kernel

#         abstract!

#         # The width of the element when printed, in number of characters.
#         sig { abstract.returns(Integer) }
#         def width; end

#         sig { overridable.params(block: T.proc.params(arg0: Stream::Element).void).void }
#         def visit(&block)
#           raise "oopsie poopsie"
#         end
#       end

#       # A literal hunk of text, printed verbatim.
#       class Text < T::Struct
#         extend T::Sig
#         include Element

#         prop :string, String, factory: -> { "" }

#         sig { override.returns(Integer) }
#         def width
#           string.length
#         end

#         sig { override.params(block: T.proc.params(arg0: Stream::Element).void).void }
#         def visit(&block)
#           block.call(Stream::Text.new(string: string))
#         end
#       end

#       # A literal hunk of text, printed verbatim, but the output width is always considered zero.
#       class ControlText < T::Struct
#         extend T::Sig
#         include Element

#         prop :string, String, factory: -> { "" }

#         sig { override.returns(Integer) }
#         def width
#           0
#         end
#       end

#       # A concatenation of multiple subelements.
#       class Concat < T::Struct
#         extend T::Sig
#         include Element

#         prop :elements, T::Array[Element], factory: -> { [] }

#         sig { override.returns(Integer) }
#         def width
#           elements.reduce(0) { |sum, elt| sum + elt.width }
#         end
#       end

#       # A subdocument where the subelements will be laid out horizontally or vertically.
#       # All line break decisions will be consistent between each element, either
#       # the group is printed on one line, or every break will be new-lined.
#       class Group < T::Struct
#         extend T::Sig
#         include Element

#         prop :elements, T::Array[Element], factory: -> { [] }

#         sig { override.returns(Integer) }
#         def width
#           elements.reduce(0) { |sum, elt| sum + elt.width }
#         end
#       end

#       # Similar to group, but ensur
#       class Nest < T::Struct
#         extend T::Sig
#         include Element

#         prop :elements, T::Array[Element], factory: -> { [] }

#         sig { override.returns(Integer) }
#         def width
#           elements.reduce(0) { |sum, elt| sum + elt.width }
#         end
#       end

#       # A break between elements.
#       class Break < T::Struct; end

#       # A break between elements that always breaks the line.
#       class LineBreak < T::Struct; end
#     end

# module Stream
#   module Element
#     extend T::Sig
#     extend T::Helpers

#     abstract!

#     sig { abstract.returns(String) }
#     def to_s; end
#   end

#   class Text < T::Struct
#     extend T::Sig
#     include Element

#     prop :string, String
#     prop :hpos, T.nilable(Integer), default: nil
#   end

#   class Cond < T::Struct
#     extend T::Sig
#     include Element

#     prop :small, String
#     prop :cont, String
#     prop :tail, String
#   end

#   # An enumerable wrapper over an element.
#   class ElementStream
#     extend T::Sig
#     extend T::Generic

#     include Enumerable

#     Elem = type_member(fixed: Element)

#     sig { params(root: Element).void }
#     def initialize(root)
#       @root = T.let(root, Element)
#     end

#     sig do
#       override
#         .params(
#           block: T.proc.params(arg0: Stream::Element).returns(BasicObject)
#         )
#         .returns(ElementStream)
#     end
#     def each(&block)
#       visit(@root, &block)
#     end

#     sig do
#       params(
#         element: Element,
#         block: T.proc.params(arg0: Stream::Element).returns(BasicObject)
#       ).returns(T.self_type)
#     end
#     def visit(element, &block)
#       case element
#       when Text
#         block.call(Stream::Text.new(hpos: nil, string: element.string))
#       else
#         raise "ooops"
#       end

#       self
#     end
#   end

#   class AnnotatedElementStream
#     extend T::Sig
#     extend T::Generic

#     include Enumerable

#     Elem = type_member(fixed: Stream::Element)

#     sig { params(root: Element).void }
#     def initialize(root)
#       @stream = T.let(ElementStream.new(root), ElementStream)
#     end

#     sig do
#       override.params(
#         block: T.proc.params(arg0: Stream::Element).returns(BasicObject)
#       ).returns(AnnotatedElementStream)
#     end
#     def each(&block)
#       position = 0
#       @stream.each do |element|
#         case element
#         when Stream::Text
#           position += element.string.length
#           element.hpos = position
#           block.call(element)
#         else
#           raise "oops"
#         end
#       end

#       self
#     end
#   end

#   class << self
#     extend T::Sig

#     sig { params(doc: Doc::Element).returns(T::Enumerator[Stream::Element]) }
#     def to_stream(doc)
#       Enumerator.new do |yielder|
#         doc.visit do |e|
#           yielder.yield(e)
#         end
#       end
#     end
#   end

#   class Builder
#     extend T::Sig

#     # def write_element(root)
#     #   fitting_elements
#     # end

#     # def text(value)
#     #   data << Text.new(value)
#     # end

#     # def group(children)
#     #   data << Group.new(value)
#     #   self
#     # end
#   end

#   sig { params(stream: T::Array[Stream::Element], out: T.nilable(IO)).void }
#   def output(stream, out = nil)
#     out ||= $stdout

#     fitting_elements = 0
#     redge = WIDTH
#     hpos  = 0

#     stream.each do |element|
#       case element
#       when Stream::Text
#         out.print(element.string)
#         hpos += element.string.length
#       end
#     end
#   end
