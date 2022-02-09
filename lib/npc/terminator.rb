# typed: strict
# frozen_string_literal: true

module NPC
  # A trait that indicates that a operation is a block terminator.
  # IE some kind of control-flow operation.
  module Terminator
    include OperationTrait
  end
end
