# typed: strict
# frozen_string_literal: true

# Dependencies

require("set")
require("sorbet-runtime")
require("pp")

# The Basics

module NPC
  extend T::Sig
  extend T::Helpers

  class << self
    extend T::Sig
    extend T::Helpers
  end
end

# Base Library

require("npc/argument")
require("npc/block")
require("npc/builder")
require("npc/error")
require("npc/foldable")
require("npc/function_type")
require("npc/iteration")
require("npc/located")
require("npc/location")
require("npc/operand")
require("npc/operation")
require("npc/printer")
require("npc/pure")
require("npc/region")
require("npc/storage")
require("npc/terminator")
require("npc/trait")
require("npc/traversal")
require("npc/type")
require("npc/users")
require("npc/uses")
require("npc/value")
require("npc/verification")

# Traits

require("npc/one_region")

# Analysis

require("npc/analysis")
require("npc/pass")

# IR Dialects

require("npc/core")
