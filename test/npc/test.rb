# typed: strict
# frozen_string_literal: true

Bundler.setup(
  :default,
  :development,
  :test,
)

require "minitest/autorun"
require "minitest/spec"
require "minitest/focus"
require "pry"
require "pry-byebug"
require "objspace"

require "npc"
