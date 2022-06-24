# typed: strict
# frozen_string_literal: true

# 1) dependencies

require("sorbet-runtime")
require("npc")

# 2) core library

require_relative("wasm/ir")
require_relative("wasm/serialization")

# require("leb128")
# require("wasm/constants.rb")
# require("wasm/export.rb")
# require("wasm/func_type_table.rb")
# require("wasm/func_type")
# require("wasm/import")
# require("wasm/local")
# require("wasm/module_writer")
