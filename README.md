# NPC -- A Compiler Framework in Ruby

```
(core/module "hello_world"
  (core/func "main" [] i32
    (= %0 (wasm/i32.const 1234))
    (= %1 (wasm/i32.const 5678))
    (= %2 (wasm/i32.add %0 %1))))
```

## TODO

- Do we need an attribute dictionary
- Rename uses to users? Is there a difference?
  - Maybe operand is a use, operation is a user?
