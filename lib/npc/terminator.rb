# typed: strict
# frozen_string_literal: true

module NPC
  # A trait that indicates that a operation is a block terminator.
  # IE some kind of control-flow operation.
  module Terminator
    include OperationTrait
  end

  # A trait indicating that blocks under this operation are implicitly
  # terminated. An implicitly terminated block does not require a proper terminator.
  # The core verifier detects this trait when verifying control flow.
  module NoTerminator
    include OperationTrait
  end
end
