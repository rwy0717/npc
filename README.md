# NPC: A Compiler Framework in Ruby

NPC is a generic high-level framework for writing compilers, heavily (heavily!) based on MLIR in the LLVM-Project.

```
module[name: example] { 
  function[name: test] {
    ^block0:
      %0: i32 = i32.const[value: 123];
      %1: i32 = i32.const[value: 456];
      %2: i32 = i32.add(%0, %1);
      goto(%1, %2)(^block1);
    ^block1(%3: i32, %4: i32):
      %5: i32 = i32.const[value: 111];
      return(%3);
  };
  function[name: another_test] { (%0: i32) ->
    %1: i32 = i32.const[value: 789];
    return(%1);
  };
};
```

## Using NPC

Add this to your gemfile:

```
gem "npc", git: "https://github.com/rwy0717/npc.git"
```

NPC uses sorbet for type-checking. Sorbet should be run with the option:

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
