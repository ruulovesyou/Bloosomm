# Blossom UI Library handoff

Updated 2026-11-17. The video-fidelity pass, standalone bundle generator, example hub script, and GitHub publishing structure are complete and verified headlessly.

## Public API

`Blossom.new(options)` returns `AddPage`, `SelectPage`, `GetValue`, `SetValue`, `GetValues`, `GetControls`, `GetControl`, `RevealControl`, `SetTheme`, `SetThemePreset`, `GetThemePresets`, `SetScale`, `SetVisible`, profile methods (`CreateProfile`, `OverwriteProfile`, `DeleteProfile`, `ListProfiles`, `LoadProfile`, `SetAutoloadProfile`, `ExportProfiles`, `ImportProfiles`), and `Destroy`.

`page:AddSection` returns `AddToggle`, `AddSlider`, `AddRangeSlider`, `AddDropdown`, `AddButton`, `AddTextInput`, `AddKeybind`, `AddColorPicker`, `AddListBox`, `MoveTo`, `Detach`, `SetCollapsed`, and `IsCollapsed`. Dropdowns accept `Multi = true`; sections accept `Description`, `Collapsible`, and `Collapsed`; toggles accept display-only `Keybind` and `Color` accessories.

Rayfield-style wrapper methods are also provided: `CreateWindow`, `CreateTab`, `CreateSection`, `CreateToggle`, `CreateSlider`, `CreateDropdown`, `CreateButton`, `CreateInput`, `CreateKeybind`, `CreateColorPicker`, `Notify`, `Save`, `Load`, `DeleteConfig`, `ChangeTheme`, and `GetThemePresets`.

## Architecture

- `Core/Store`: canonical values and protected callbacks.
- `Core/Records`: pure search, color and keybind validation.
- `Core/ProfileStore`: session profile snapshots and injectable persistence callback.
- `Core/ModalManager`: blocking modal layer and Escape dismissal.
- `Core/OverlayManager`: one nonblocking popup.
- `Components/RangeSlider`: normalized two-handle range control.
- `Components/Section`: animated accordion behavior; heading drag remains available for layout moves.
- `Core/LayoutManager`: section move/detach and serializable layout records.
- `Core/KeybindManager`: UI-only key capture and toggle/hold state.
- `Core/ColorAnimator`: throttled preview animation.
- `Components/SearchDialog`, `Keybind`, `ColorPicker`, `ListBox`: advanced UI components.
- `Themes/Presets`: ten named approximate themes.

The entry point initializes every manager in one context, preserving Store ownership and scoped cleanup. No remotes, gameplay logic, executor APIs or DataStores are used.

## Standalone Bundle & Example Hub

- `Bloosoom UI Library/Source/Blossom/Blossom.lua`: Single-file bundle using a virtual node/register tree (`__node` / `__register` / `__require`), allowing all 32 modules to run under `loadstring` without requiring external files.
- `Bloosoom UI Library/example-hub.lua`: Complete multi-tab script using `loadstring(game:HttpGet("https://raw.githubusercontent.com/ruulovesyou/Bloosomm/main/Blossom/Blossom.lua"))()`.
- `tools/build_bundle.py`: Standalone Python script to regenerate the bundle from source.
- `build.lua`: Lune-compatible builder supporting `--local`.

## GitHub Publishing Layout

Target repository: `https://github.com/ruulovesyou/Bloosomm` (`main` branch)

```
Blossom/
  Components/
  Core/
  Themes/
  Blossom.lua      <-- resolves at https://raw.githubusercontent.com/ruulovesyou/Bloosomm/main/Blossom/Blossom.lua
  init.luau
example-hub.lua
```

## Verification

Run `powershell -File tools/verify.ps1`. It compiles 36 Luau files, runs 13 headless tests, checks canonical/distribution source sync (32 modules matching byte-for-byte), performs strict analysis on pure modules, builds library and demo models with Rojo, and validates package dependencies. Compile `Bloosoom UI Library/Source/Blossom/Blossom.lua` and `example-hub.lua` with `.tools/luau/luau-compile.exe --null`.
