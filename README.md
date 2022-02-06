# NPC: A Compiler Framework in Ruby

NPC is a generic high-level framework for writing compilers, heavily (heavily!) based on MLIR in the LLVM-Project.

```
module { 
  function[name: test] {
    ^block0:
      %0: i32 = i32.const[value: 123];
      %1: i32 = i32.const[value: 456];
      %2: i32 = i32.add(%0, %1);
      goto(%1, %2)(^block1);
    ^block1(%3: i32, %4: i32):
      %5: i32 = i32.const[value: 111];
  };
  function[name: another_test] { (%0: i32) ->
    %1: i32 = i32.const[value: 789];
  };
}
```

## Using NPC

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

## Development

```
git clone https://github.com/rwy0717/npc
cd npc
bundle install
bundle exec rake test
```

## TODO

- Do we need an attribute dictionary
- Rename uses to users? Is there a difference?
  - Maybe operand is a use, operation is a user?
