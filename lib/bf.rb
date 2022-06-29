# typed: strict
# frozen_string_literal: true

require("singleton")
require("sorbet-runtime")
require("npc")

require("bf/compiler")
require("bf/interpreter")
require("bf/ir")
require("bf/irgen")
require("bf/transformations/simplify_repetitions")
