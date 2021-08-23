# typed: strict
# frozen_string_literal: true

module NPC
  # A value that can be referenced or used within IR.
  class Value
    include Base

    sig { params(first_use: T.nilable(Use)).void }
    def initialize(first_use = nil)
      @first_use = T.let(first_use, T.nilable(Use))
    end

    sig { returns(T.nilable(Use)) }
    attr_accessor :first_use

    # If this is the result of an operation, get that operation.
    sig { returns(T.nilable(Operation)) }
    def defining_operation
      nil
    end

    ## The users of this.

    # sig { params(other: Usable) }
    # def replace_all_uses
    #   # TODO
    # end

    ## Does this have no uses?
    sig { returns(T::Boolean) }
    def unused?
      first_use.nil?
    end

    # Does this have any uses?
    sig { returns(T::Boolean) }
    def used?
      first_use != nil
    end

    # Does this have exactly one use?
    sig { returns(T::Boolean) }
    def used_once?
      use = first_use
      if use
        use.next_use.nil?
      else
        false
      end
    end

    # An enumerable collection of all uses.
    sig { returns(Uses) }
    def uses
      Uses.new(self)
    end

    ## An enumerable collection of all users (which must be operations).
    # sig { returns(Users) }
    # def users
    #   Users.new(self)
    # end
  end
end
