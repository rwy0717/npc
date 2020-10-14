# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = 'npc'
  spec.version     = '0.0.1'
  spec.date        = '2020-10-08'
  spec.summary     = "Nanopass Compiler"
  spec.description = "A simple compiler framework"
  spec.authors     = ["Robert Young"]
  spec.email       = 'rwy0717@gmail.com'
  spec.homepage    = 'https://rubygems.org/gems/npc'
  spec.license = 'DO NOT USE OR DISTRIBUTE'
  spec.files       = [
    "lib/leb128.rb"
    "lib/npc.rb",
    "lib/wasm.rb",
    "lib/npc/boot.rb",
    "lib/npc/lang.rb",
    "lib/npc/meta.rb",
    "lib/npc/sexpr.rb"
    "lib/npc/wasm.rb",
    "lib/npc/x64.rb"
  ]
end
