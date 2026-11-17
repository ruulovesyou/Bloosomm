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

local window = Blossom:CreateWindow({
    name = "Blossom",
    subtitle = "Blossom UI Library",
    theme = "Blossom",
})

local tab = window:CreateTab({
    name = "Home",
})

tab:CreateSection({name = "Controls"})

tab:CreateToggle({
    name = "Enabled",
    value = false,
    callback = function(value)
        print("Enabled:", value)
    end,
})
```

The public entry point is `Source/Blossom/init.luau`. `BlossomUI.luau` remains as a convenience facade for projects that already installed the built library model. For the complete API, read the repository-level README.

This library is UI-only. It does not contain remotes, gameplay logic, executor code, DataStores, or file persistence. Run it from a client `LocalScript` because it creates UI under `PlayerGui`.
