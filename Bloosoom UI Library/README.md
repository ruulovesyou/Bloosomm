# Blossom UI Library — standalone Luau distribution

This folder is the GitHub-style library distribution. It contains the complete 31-module Luau source tree under `Source/Blossom`, separate from the demo and repository tooling.

## Install with Rojo

Run from this folder:

```powershell
rojo build Blossom.project.json --output Blossom.rbxmx
```

Insert the resulting `Blossom.rbxmx` model into `ReplicatedStorage` as `Blossom`, then require it from a `LocalScript`:

```lua
local Blossom = require(game:GetService("ReplicatedStorage"):WaitForChild("Blossom"))

local ui = Blossom.new({
    Title = "Blossom",
    Theme = "Blossom",
})

local page = ui:AddPage({
    Id = "demo",
    Title = "Demo",
    Group = "General",
})

local section = page:AddSection({
    Id = "controls",
    Title = "Controls",
    Column = 1,
})

section:AddToggle({
    Id = "enabled",
    Label = "Enabled",
    Default = false,
})
```

The public entry point is `Source/Blossom/init.luau`. `BlossomUI.luau` remains as a convenience facade for projects that already installed the built library model. For the complete API, read the repository-level README.

This library is UI-only. It does not contain remotes, gameplay logic, executor code, DataStores, or file persistence. Run it from a client `LocalScript` because it creates UI under `PlayerGui`.
