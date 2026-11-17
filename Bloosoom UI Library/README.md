# Blossom UI Library — standalone Luau distribution

This folder is the GitHub-style library distribution. It contains the complete 32-module Luau source tree under `Source/Blossom`, separate from the demo and repository tooling.

## Quick Start (loadstring)

Load the pre-built single-file bundle directly via GitHub:

```lua
local Blossom = loadstring(game:HttpGet("https://raw.githubusercontent.com/ruulovesyou/Bloosomm/main/Blossom/Blossom.lua"))()

local win = Blossom:CreateWindow({
    Name = "Blossom Hub",
    Subtitle = "example",
    Theme = "Blossom",
    Size = UDim2.fromOffset(420, 340),
})
```

See [example-hub.lua](file:///C:/Dev/Projec/GUI/Bloosoom%20UI/Bloosoom%20UI%20Library/example-hub.lua) for a complete multi-tab script with Toggles, Sliders, Dropdowns, ColorPickers, Keybinds, ESP, and Config Profiles.

## GitHub Repository Structure

When publishing to `ruulovesyou/Bloosomm` (`main` branch), the repository layout must have `Blossom/` at the root so that `https://raw.githubusercontent.com/ruulovesyou/Bloosomm/main/Blossom/Blossom.lua` resolves:

```
Blossom/
  Components/
  Core/
  Themes/
  Blossom.lua      <-- single-file loadstring bundle
  init.luau        <-- modular Luau entry point
example-hub.lua    <-- complete example script
```

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

## Structure & Building

- `Source/Blossom/init.luau`: Canonical modular entry point.
- `Source/Blossom/Blossom.lua`: Single-file bundle generated with virtual module tree (`__node` / `__register` / `__require`), enabling `loadstring` without file system access.
- `Blossom.lua`: Root copy of the bundle for direct inclusion.
- `example-hub.lua`: Full hub script using `loadstring`, tabs, sections, loops, highlights, and profile saving.
- `tools/build_bundle.py`: Rebuilds `Blossom.lua` from source files in seconds (`python tools/build_bundle.py`).
- `build.lua`: Lune-compatible builder (`lune run build.lua --local`).

This library is UI-only. It creates UI under `PlayerGui` or `CoreGui`. It does not contain server remotes, gameplay exploits, or file system access.
