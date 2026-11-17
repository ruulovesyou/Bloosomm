# Blossom UI Library — foundation

Native Roblox Luau UI recreation, scoped to approximately the first half of the supplied blueprint. All demonstration values are inert; the library makes no gameplay changes, network requests or persistent writes.

## Run

Generated files are in `build/` (ignored, reproducible):

- Open `build/BlossomDemo.rbxlx` in Roblox Studio if you want to inspect the package manually. Delivery verification is headless and does not require Studio.
- For an existing place, insert `build/Blossom.rbxmx` into **ReplicatedStorage**, preserving the ModuleScript name `Blossom`. Require it from a **LocalScript**. The model includes all child modules.
- Alternatively use Rojo: `rojo serve default.project.json`, then connect the Rojo Studio plugin. The CLI alone does not install a Studio plugin.

No tools are needed at runtime. Build with Rojo 7.7.1:

```powershell
New-Item -ItemType Directory -Path build -Force
rojo build default.project.json --output build/BlossomDemo.rbxlx
rojo build library.project.json --output build/Blossom.rbxmx
rojo build tests/studio.project.json --output build/BlossomSmokeTests.rbxlx
```

For manual source import: create `ReplicatedStorage.Blossom` as a ModuleScript with `src/Blossom/init.luau` as its source. Reproduce Core, Components and Themes as child Folders and each `.luau` file as a ModuleScript. Put `src/Demo/DemoApp.client.luau` in a LocalScript under StarterPlayerScripts. Do not create a child ModuleScript named `init`.

## Minimal example

```lua
local Blossom = require(game:GetService('ReplicatedStorage'):WaitForChild('Blossom'))
local ui = Blossom.new({Title = 'Blossom', Scale = 1.25, ReducedMotion = false})
local page = ui:AddPage({Id = 'demo', Title = 'Demo', Group = 'General'})
local section = page:AddSection({Id = 'controls', Title = 'Controls', Column = 1})
local toggle = section:AddToggle({
    Id = 'enabled', Label = 'Enabled', Default = false,
    OnChanged = function(value) print('UI state:', value) end,
})
section:AddSlider({Id = 'amount', Label = 'Amount', Minimum = 0, Maximum = 100, Step = 1, Default = 25})
section:AddDropdown({Id = 'mode', Label = 'Mode', Options = {'One', 'Two'}})
section:AddTextInput({Id = 'name', Label = 'Name', Placeholder = 'Enter name', MaxLength = 40})
section:AddButton({Id = 'reset', Label = 'Reset', OnClick = function() toggle:SetValue(false) end})
-- ui:Destroy() when the owning application closes.
```

## Public contract

| API | Contract |
| --- | --- |
| `Blossom.new(options?)` | Client-only; optional PlayerGui `Parent`, `Title`, pixel-offset `Size` (default 422×336, minimum 360×260), `Scale` (0.5–3), `ReducedMotion`, `DisplayOrder`. `Theme` accepts `"Blossom"` or a token override table. |
| `ui:AddPage({Id, Title, Group?})` | Returns page; first page becomes selected. Groups ordered by first appearance; absent/empty Group has no heading. |
| `ui:SelectPage(id)` | Shows exactly one page; keeps values and column scroll positions. Closes popup, commits focused text and cancels drag. |
| `page:AddSection({Id, Title, Column?, Order?})` | Returns content-sized section in column 1 or 2. Default column 1, creation-order position. No section drag yet. |
| `section:AddToggle/AddSlider/AddDropdown/AddButton/AddTextInput(options)` | Returns control handle. All require globally unique `Id` and visible `Label`; support `Disabled`. |
| `control:GetValue() / SetValue(value)` | Value controls only; same normalization path as user interaction. Button handles deliberately reject value methods. |
| `control:SetDisabled(boolean)` | Prevents user input; programmatic value changes remain permitted. Disabling an input discards its pending draft. |
| `ui:GetValue(id) / SetValue(id, value)` | Same Store path; buttons have no value. Unknown IDs reject. |
| `ui:GetValues()` | Independent table of scalar values, excluding buttons. No persistence. |
| `ui:GetControls()` | ID-sorted array of frozen metadata: Id, Label, Type, PageId, PageTitle, SectionId, SectionTitle. Includes buttons. |
| `ui:GetControl(id)` | Handle with `Frame`, `Label`, `Metadata`, `Id`. Frame is exposed for later reveal/highlight; don't reparent/destroy it independently. |
| `ui:SetTheme(overrides)` | Partial table of known Color3 tokens; validates before repaint. Closes popup. No preset selector/editor implemented. |
| `ui:SetScale(number)` | Updates the single UIScale; cancels drag, closes popup and clamps window. |
| `ui:SetVisible(boolean)` | Hides/shows root, preserves state. Hiding commits focused text, closes popup and cancels drag. |
| `ui:Destroy()` | Idempotent; disconnects library listeners, cancels tweens/drag, disposes popup and ScreenGui. Handles cannot be reused. |

Control-specific options:

| Control | Options and behavior |
| --- | --- |
| Toggle | Boolean `Default` (false), `OnChanged(value)` |
| Slider | `Minimum` (0), `Maximum` (100), positive `Step` (1), numeric `Default` (minimum), string `Unit`, `OnChanged(value)`. Snaps relative to minimum; endpoints reachable; finite numbers required. Mouse/touch drag and arrows/D-pad while natively selected. |
| Dropdown | Nonempty unique string `Options`, string `Default` (first option), `OnChanged(value)`. Options are copied. Single selection, scrollable popup, upward placement, outside-click/Escape dismissal. |
| Button | `OnClick()`; synchronous protected callback. No canonical value. |
| TextInput | String `Default` (empty), `Placeholder`, integer `MaxLength` (200 Unicode characters), `OnChanged(value)`, `OnSubmitted(value)`. Commits on focus loss; Enter also submits. Draft stays local during editing/IME. External changed value overwrites draft. |

Callbacks are synchronous, protected against errors, and should be short/non-yielding. Value callbacks are not called on construction or unchanged normalized values. Programmatic SetValue does call OnChanged when changed. No per-control removal API in this phase. Create a new library instance after Destroy.

Theme keys: Background, Sidebar, Tab, Section, Input, Outline, Inline, Text, InactiveText, Accent, Element, HoveredElement, Gradient, Shadow. Geometry/motion live in `Themes/Tokens.luau`. Gradient is reserved, not rendered. Icons are native geometric approximations, not original assets.

## Verification and limitations

Run `powershell -File tools/verify.ps1` with official Luau CLI 0.747 and Rojo 7.7.1 in `.tools/luau` and `.tools/rojo`, or pass `-LuauDirectory` and `-Rojo` paths. Python 3 is used only to inspect generated XML module graphs. Obtain tools from [Luau releases](https://github.com/luau-lang/luau/releases) and [Rojo releases](https://github.com/rojo-rbx/rojo/releases). No dependency downloader runs automatically.

Headless tests cover state, validation, search, color/keybind records, profiles and cleanup. Rojo builds and package checks are the delivery verification; Roblox Studio execution is intentionally excluded.

The 422×336 default, small fonts and two columns target the desktop recording. Scale up for readability; very small viewports can clip a window larger than the viewport. Effects and Exploits intentionally have empty pages because reference content is unknown.

Search, keybind editing, color pickers, theme presets, profiles and detachable/reorderable sections are included. Start with HANDOFF.md for the public API and file map.

## Reference and implementation evidence

`reference/blossom-library-ui-recreation.md` is the complete provided blueprint. `reference/recording-00m02s.png` is an unmodified extracted frame from the supplied recording, not an implementation screenshot.

Roblox documents that InputObject.Position and GuiBase2d.AbsolutePosition share the CoreUISafeInsets coordinate system. Pointer calculations compare them directly; do not subtract GetGuiInset a second time. Sources: [GuiBase2d](https://create.roblox.com/docs/reference/engine/classes/GuiBase2d), [InputObject](https://create.roblox.com/docs/reference/engine/classes/InputObject). Column sizing uses [AutomaticCanvasSize](https://create.roblox.com/docs/ui/size-modifiers).
