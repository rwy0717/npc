# typed: strict
# frozen_string_literal: true

module NPC
  module Core
    class Call < Operation
      extend T::Sig
      extend T::Helpers

      sig do
        params(
          callee: Symbol,
          arguments: T::Array[Value]
        ).void
      end
      def initialize(callee, arguments)
        super()

        @callee    = callee
        @arguments = arguments
      end

      #       argument :callee, FlatSymbolRef
      #       argument :operands, Variadic[AnyType]
      #
      #       let arguments = (ins FlatSymbolRefAttr:$callee, Variadic<AnyType>:$operands);
      #       let results = (outs Variadic<AnyType>);
    end
  end
end
