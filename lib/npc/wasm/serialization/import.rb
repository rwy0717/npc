# typed: strict
# frozen_string_literal: true

module NPC
  module WASM
    class ImportType < T::Enum
      extend T::Sig

      enums do
        Func = new("FUNC")
        Table = new("TABLE")
        Mem = new("MEM")
        Global = new("GLOBAL")
      end

      sig { returns(String) }
      def code
        case self
        when Func
          "\x00"
        when Table
          "\x01"
        when Mem
          "\x02"
        when Global
          "\x03"
        end
      end

      sig { params(out: IO).void }
      def write(out)
        out.write(code)
      end
    end

    class Import < T::Struct
      extend T::Sig

      prop :mod, String
      prop :name, String
      prop :type, ImportType
      prop :index, Integer

      sig { params(out: IO).void }
      def write(out)
        type.write(out)
        out.write(mod)
        out.write(name)
        type.write(out)
      end
    end
  end
end
