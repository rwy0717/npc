# typed: true
# frozen_string_literal: true

require("leb128")
require("sorbet-runtime")

require("wasm/constants.rb")
require("wasm/export.rb")
require("wasm/func_type_table.rb")
require("wasm/func_type")
require("wasm/import")
require("wasm/local")
require("wasm/module_writer")
