# # typed: strict
# frozen_string_literal: true
# # frozen_string_literal: true

# module Flow

#   class GQLSchema
#   end

#   class Source
#   end

#   class GQLSource < Source
#   end

#   class GQLField
#     extend T::Sig

#     sig { params(name: String, arguments: T::Hash[String, T.untyped]).void }
#     def initialize(name, arguments)
#       @name = T.let(name, String)
#       @arguments = T.let(arguments, T::Hash[String, T.untyped])
#     end

#     sig { returns(String) }
#     attr_accessor :name

#     sig { returns(T::Hash[String, T.untyped]) }
#     attr_accessor :arguments
#   end

#   class GQLPath
#     extend T::Sig

#     sig in
#     source: Source
#     path: GQLQuery
#   end

#   # A reference datatype.
#   # encoded in a reference type is the hydration mechanism.
#   module Reference
#     extend T::Sig

#     sig { abstract.returns(Source) }
#     def source; end

#     sig { abstract.returns(GQLPath) }
#     def path; end
#   end

#   class GQLReference
#     extend T::Sig

#     sig { params(source: GQLSource).void }
#     def initialize(source)
#       @source = T.let(source, GQLSource)
#     end

#     sig { returns(GQLSource) }
#     def source
#       @source
#     end
#   end

#   class ArrayReference
#     extend T::Sig
#   end

#   # Create a constant reference to a graphql reference
#   class ConstGQLRef < NPC::Operation
#     class << self
#       extend T::Sig
#     end

#     extend T::Sig

#     sig { void }
#     def initialize
#       super
#       new_result
#     end

#     sig { void }
#     def source
#     end
#   end
# end
