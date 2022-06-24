# NPC::WASM

A webassembly dialect for NPC with output to binary webassembly modules.

## Usage

WASM support is not included in NPC by default, it has to be explicitly required:

```ruby
require("npc/wasm")
```

## Additional Tools Recommended for Development

- Running WASM modules: wasmtime
- Dumping WASM modules to text: wasm2wat from WABT.
