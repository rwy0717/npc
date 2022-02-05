# NPC: A Compiler Framework in Ruby

NPC is a generic high-level framework for writing compilers, heavily (heavily!) based on MLIR in the LLVM-Project.

```
(core/module "hello_world"
  (core/func "main" [] i32
    (= %0 (wasm/i32.const 1234))
    (= %1 (wasm/i32.const 5678))
    (= %2 (wasm/i32.add %0 %1))))
```

## Setting up NPC

Add this to your gemfile:

```
gem "npc", version "~> 0.1.0"
```

NPC uses sorbet. Sorbet must be run with the option:

```
--enable-experimental-requires-ancestor
```

This option can be placed in the file `sorbet/config`, to ensure
sorbet is always run with it.

## TODO

- Do we need an attribute dictionary
- Rename uses to users? Is there a difference?
  - Maybe operand is a use, operation is a user?
