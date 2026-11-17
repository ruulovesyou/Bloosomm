# Bloosoom UI Library

`BlossomUI.luau` is the copyable public entry point. Place the built `Blossom.rbxmx` model from `build/` in `ReplicatedStorage` as `Blossom`, then place this ModuleScript wherever your project keeps client libraries.

```lua
local Blossom = require(path.to.BlossomUI)
local ui = Blossom.new({Title = 'Blossom'})
```

The complete source remains under `src/Blossom`; the standalone entry point avoids duplicating the implementation and drifting from the tested package.
