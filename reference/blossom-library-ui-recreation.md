# Blossom Library UI — Recreation Blueprint

> **Purpose:** A comprehensive, implementation-ready specification for recreating the **visual UI library** demonstrated in the user-provided screen recording, `Recording 2026-11-16 215022.mp4` (approximately 1 minute 40 seconds).  
> **Target:** A modular Roblox/Luau-style in-game settings window, or an equivalent mock interface in another UI framework.  
> **Scope:** Layout, rendering, visual hierarchy, reusable widgets, navigation, search, drag-and-drop, theming, profiles, and interaction states. **No game-altering behavior is specified or required.**  
> **Accuracy policy:** **Observed** means clearly visible in the recording; **estimated** means a recreation target derived from screen pixels; **proposed** means an implementation choice that is not verified by the video.

---

## 1. Design goals

Recreate the recorded **Blossom** interface as a compact, professional, dark-first UI library. It should feel like a densely packed desktop settings panel placed over a Roblox scene, not a full-screen application.

**Required qualities**

1. Dark, slightly warm charcoal surfaces with a muted blue accent in the default theme.
2. Small but carefully aligned labels, compact interactive rows, subtle outlines, and rounded corners.
3. Fixed left navigation rail with grouped page links and a bottom search trigger.
4. Two vertical content columns containing independently stacked section panels.
5. Reusable switches, sliders, dropdowns, buttons, keybinds, color pickers, text inputs, and list controls.
6. Detachable/reorderable sections as demonstrated in the recording.
7. Layered popups: dropdowns, keybind menus, color pickers, and a centered search overlay.
8. Persistent UI state and a multi-preset theme engine.
9. All interactions implemented for the **interface itself**, even when the underlying example feature does nothing.

**Non-goals:** Building the example game's combat, movement, targeting, exploit, or other game-affecting logic; reverse-engineering the original source; claiming pixel-perfect reproduction from a compressed screen recording.

---

## 2. Evidence index from the recording

| Approx. timestamp | Observed interface/interaction | Recreation relevance |
|---|---|---|
| 00:00–00:04 | Default dark theme; Rage page, two columns | Master layout, toggles, sliders, category headings |
| 00:05–00:08 | Movement and Players/visual page examples | Page switching, differing panel heights |
| 00:10–00:14 | Search overlay, live query/results | Global search design |
| 00:15–00:24 | Sections moved and rearranged | Detached cards, drag previews, drop locations |
| 00:30–00:35 | Keybind control and mini contextual menu | Toggle/hold/reset keybind UI |
| 00:45–00:56 | Dropdowns and color picker, animation choices | Popup placement and color editor |
| 00:57–01:01 | Legit page with multiple groups | Independent two-column section stacks |
| 01:02–01:13 | Settings, Profiles, palette editing, Menu | Configuration and theme editor layout |
| 01:17–01:26 | Theme dropdown and drastic palette switches | Theme presets and full-token application |
| 01:27–01:38 | Orange-accent theme, keybind menu, search for “speed” | Theme fidelity, search result rows |

*Times are approximate; the recording is the only evidence. Some controls or values are partially obscured at certain moments.*

---

## 3. Visual overview

### 3.1 On-screen proportions

The main UI appears **approximately 420–425 px wide and 330–345 px tall at the captured video scale**. This is an **estimate of the recorded rendering**, not a verified original Roblox `UDim2` value.

| Dimension | Approximate recreation target | Confidence |
|---|---:|---|
| Main window | 422 × 336 px | Estimated |
| Left navigation | 101–105 px wide | Estimated |
| Main content region | 315–320 px wide | Estimated |
| Content inset/gutters | 7–10 px | Estimated |
| Two content columns | roughly 147–151 px each | Estimated |
| Space between columns | 7–10 px | Estimated |
| Outer corner radius | 6–8 px | Estimated |
| Section/card corner radius | 4–6 px | Estimated |
| Sidebar row height | 21–24 px | Estimated |
| Compact input/button height | 18–22 px | Estimated |
| General body labels | ~9–11 px at video scale | Estimated |
| Brand title | ~12–14 px at video scale | Estimated |

**Scaling rule:** Treat these as reference proportions. Offer a single `UIScale` setting so text and hit targets remain usable at different resolutions. Do not hard-code every width relative to the video image.

### 3.2 Screen wireframe

```text
┌──────────────────────────────────────────────────────────┐
│ ○ Blossom       Section A                Section B      │
│                 ───────────────────       ─────────────   │
│ Combat          [ control + switch ]      [ toggle ]      │
│ ● Rage          [ label + slider ]        [ dropdown ]    │
│   Legit         [ label + dropdown ]      [ slider ]      │
│                                                          │
│ Visuals         Section C                 Section D      │
│   Players       ───────────────────       ─────────────   │
│   Effects       [ toggle + chip ]         [ toggle ]      │
│                                                          │
│ Player                                                   │
│   Movement                                               │
│   Exploits                                               │
│                                                          │
│ ● Settings                                               │
│                                                          │
│ [⌕ Search...]                                            │
└──────────────────────────────────────────────────────────┘
  ~102px sidebar   ~150px first column   ~150px second
```

*Diagram represents the structure, not the exact content or positions of every section.*

### 3.3 Distinctive visual characteristics

- The window overlays the gameplay environment without obscuring the whole screen.
- No large hero imagery, decorative gradients, or prominent borders in the default theme.
- Background and cards are differentiated with **small luminance changes**, not strong strokes.
- Icons are small, monochrome or muted, generally preceding labels.
- Accent appears on active switches, slider fill, selected options, cursor/selection marks, and some icons.
- Numbers and keybind indicators are subdued, aligned to the right.
- Empty space below short panels is allowed; panels do **not** stretch to fill the window.
- Popup elements are rendered above the window rather than altering the normal layout.

---

## 4. Color and typography tokens

The recording does not expose its exact color constants or font assets. The values below are **proposed approximate starting tokens**, chosen to reproduce the *observed* default visual relationship. They should be tuned against reference screenshots during implementation.

### 4.1 Default palette (`Blossom`) — approximate

| Token | Suggested HEX | Application |
|---|---|---|
| `background` | `#1D1F22` | Window shell |
| `sidebar` | `#1B1D20` | Left rail |
| `tab` | `#25272B` | Content area/card surfaces |
| `section` | `#292B2F` | Section body or nested controls |
| `input` | `#25272A` | Dropdowns, textboxes, button surfaces |
| `outline` | `#383B40` | Hairline separators and subtle borders |
| `inline` | `#303338` | Inner row/subtle inset |
| `text` | `#E3E6EA` | Main text |
| `textMuted` | `#8D929B` | Group names, disabled text, value hints |
| `accent` | `#74A9E3` | Active toggles and progress fills |
| `element` | `#33363C` | Neutral components |
| `hoveredElement` | `#3A3D43` | Hover/selection backgrounds |
| `gradient` | `#C8D4E3` | Optional gradient accents; varies by theme |
| `shadow` | `#000000` | Window/popup shadows |

The themed color labels actually visible in **Settings → Theming** include: **Background, Tab, Outline, Inline, Text, Inactive Text, Accent, Element, Gradient, Shadow, Hovered Element**. These names should be preserved in the user-facing theme editor. The internal token naming may differ.

### 4.2 Typography

- **Observed:** A small, crisp, sans-serif UI font with stronger weights for the brand, section titles, and selected options.
- **Not verifiable:** Exact font name and weight metrics.
- **Proposed:** `Gotham`/`GothamMedium` in Roblox, or `Inter` in a web prototype.
- Brand: semibold/bold; navigation: medium; section header: medium; group label: regular/small/muted; values: regular/small.
- Use consistent baseline alignment. Avoid decorative uppercase text except where intentionally present.
- Do not enlarge labels excessively if pursuing screenshot similarity; add an optional accessibility scale instead.

### 4.3 Shape and elevation

| Element | Suggested treatment |
|---|---|
| Main shell | 6–8 px corners, soft dark drop shadow |
| Sidebar selected item | 4–5 px radius, low-contrast filled background |
| Section | 4 px corners, subtle inner fill |
| Primary controls | 3–4 px corners |
| Toggle | Narrow pill with circular knob |
| Slider | 3–4 px tall track; small round handle |
| Dropdown popup | Dark rectangle, subtle stroke, light shadow, internal scrolling |
| Color picker | Floating layered panel with distinct inner controls |
| Search overlay | Centered larger modal, dimmed/obscured background |

---

## 5. Layout and navigation

### 5.1 Top-level structure

```text
ScreenGui / UI Root
└── WindowRoot                     [draggable window]
    ├── OuterShadow
    ├── WindowBackground
    ├── Sidebar                    [fixed width]
    │   ├── Branding
    │   │   ├── CircularLogo
    │   │   └── Title: Blossom
    │   ├── NavigationGroup: Combat
    │   │   ├── Rage
    │   │   └── Legit
    │   ├── NavigationGroup: Visuals
    │   │   ├── Players
    │   │   └── Effects
    │   ├── NavigationGroup: Player
    │   │   ├── Movement
    │   │   └── Exploits
    │   ├── NavigationItem: Settings
    │   └── SearchTrigger            [anchored bottom]
    ├── ContentPane
    │   ├── LeftColumn               [vertical independently stacked sections]
    │   └── RightColumn              [vertical independently stacked sections]
    └── OverlayLayer                 [higher z-order than regular content]
        ├── DropdownPopup
        ├── KeybindPopup
        ├── ColorPickerPopup
        ├── DragPreview
        └── SearchDialog
```

### 5.2 Sidebar

**Observed category labels and navigation:**

| Category | Visible page names |
|---|---|
| Combat | Rage, Legit |
| Visuals | Players, Effects |
| Player | Movement, Exploits |
| Bottom/general | Settings |

Rules:

1. Brand icon and `Blossom` text sit near the top-left, on one line.
2. Tiny muted category titles precede each group.
3. Navigation entries have a left icon, then a text label; selected item has a quiet filled pill/rectangle.
4. Only one main page is active at once.
5. Sidebar remains visible while content scrolls or panels are rearranged.
6. Search trigger stays anchored at bottom with a magnifying-glass icon and `Search...` placeholder.
7. A selected tab changes the active content immediately; a short color transition is optional.

### 5.3 Main content

- Use **two columns**, left and right, with independent section stacks.
- Each section has a header title with a small leading icon.
- Within sections, controls appear as compact rows or small vertical clusters.
- A section may have toggles, multiple sliders, text/dropdown fields, color swatches, and keybind chips.
- Section heights follow their content; both columns need not end at the same Y coordinate.
- Preserve enough padding between rows to prevent text collisions at 100% UI scale.
- The window does not visibly resize when tabs change; treat its size as stable in the first recreation.

---

## 6. Reusable component specification

### 6.1 `Section`

**Appearance:** Header icon + title above/in a low-contrast card region; body stacks controls. In the recording, example headers include `Ragebot`, `Silent Aim`, `Targeting`, `Anti Aim`, `Aim Assist`, `Triggerbot`, `Misc`, `Recoil Control`, `Movement`, `Bunny Hop`, `Profiles`, `Theming`, and `Menu`.

**State:** `id`, `title`, `icon`, `column`, `order`, `collapsed?`, `detached?`, `position?`.

**Behavior:** Drag using header; show a floating panel while dragging; allow a drop into either column; preserve UI state on tab changes. Header-driven dragging is **observed**; exact placement algorithm is **proposed**.

### 6.2 `Toggle`

**Appearance:** Small right-aligned pill switch, accent-colored when active, gray/dark when inactive. Tiny white/light knob. Text label left.

**State:** `value: boolean`, `disabled?: boolean`.

**Behavior:** Click toggles immediately; visual transition should be short. Parenthesized shortcuts or keybind chips can coexist with the toggle.

**Sizes (proposed):** 20–22 px wide × 11–13 px tall; increase invisible hit area if used interactively on touch.

### 6.3 `Slider`

**Appearance:** Label and subtle numerical value; horizontal line track beneath, muted unfilled side, blue filled side, small round handle. Multiple sliders can share a single section with very small vertical spacing.

**State:** `min`, `max`, `step`, `value`, `unit?`, `format?`.

**Behavior:** Pointer drag updates progress and number; clamp to range; step/snap where appropriate. For tests, use illustrative values rather than asserting values visible in the recording are original defaults.

### 6.4 `Dropdown`

**Appearance:** Narrow rectangular dark input with selected label left and small dropdown icon right. Options appear in a darker floating list, visually aligned to the input width.

**State:** `options`, `selected`, `open`, `scrollOffset`.

**Behavior:** Toggle open/closed; click option to select; scroll longer option lists; close on outside click or Escape; prefer opening upward when near the lower window edge. This overflow behavior is a **proposed** robustness rule.

### 6.5 `Keybind`

**Appearance:** Tiny keyboard key chip adjacent to an enabled control, often near the upper right of a section row.

**Observed popup:** A compact contextual panel with `On Toggle`, `On Hold`, and `Reset`. One option receives accent-colored highlighting.

**State:** `key`, `mode: 'toggle' | 'hold'`, `captureMode`, `popupOpen`.

**Behavior:** Left click may enter key capture; secondary interaction may open mode settings (precise click semantics cannot be confirmed from video). For recreation, clicking the chip opens a clearly labeled editor with capture and mode selection.

### 6.6 `ColorPicker`

**Appearance:** Floating dark rectangular popover, square saturation/value plane, narrow vertical rainbow hue strip on right, a horizontal transparency/alpha strip below, and a dropdown called `Animations`.

**Visible animation choices:** `None`, `Rainbow`, `Fade`, `Fade Alpha`.

**State:** `color` (`RGB`/`HSV`), `alpha`, `animationMode`, `open`.

**Behavior:** Drag inside square for saturation/value; drag hue strip; adjust alpha; change animation; immediately update preview swatch. Keep popover within viewport and above parent panel.

### 6.7 `Button`

**Appearance:** Full-width low-profile dark rectangle, centered short label. In light theme, buttons have pale gradients and thin borders.

**Visible examples:** `Create`, `Load`, `Delete`, `Overwrite`, `Unload`.

**Behavior:** Press with visible hover/pressed feedback; confirm destructive actions. Confirmation is a **proposed** UX safeguard, not a behavior proven by the video.

### 6.8 `TextInput`

**Appearance:** Narrow inset field with muted placeholder; minimal outer border.

**Visible examples:** `Search...`, `Config name`.

**Behavior:** Focus style; keyboard editing; placeholder hidden when text is present; submit via Enter where applicable.

### 6.9 `ListBox`

**Appearance:** Rectangular empty/list area with thin outline; used in Settings → Profiles. Items are small, aligned to top-left, selected with subtle fill/accent.

**Behavior:** Select one config; list can scroll; hover states remain understated.

### 6.10 `SearchDialog`

**Observed:** A centered, relatively large dark modal is drawn on top of an underlying dimmed interface. It includes `Search` heading, a search input, and search result rows. Results have main label, smaller contextual text, and a small colored accent strip at the left in the orange theme. Searching `speed` shows rows such as `Spin Speed`, `Speed`, `Speed Amount`, `Speed Type`, `Fly Speed`; contextual sublabels describe page/section and component type.

**Behavior specification:**

1. Click bottom sidebar search field to open modal.
2. Focus search input automatically (**proposed** if not verifiable).
3. Search all registered UI control labels and their location metadata.
4. Filter incrementally as the user types.
5. Show each result as `Control Name` followed by `Page / Section · Component Type`.
6. Click result to navigate to its page and reveal/focus/highlight the control; the recording visually supports navigation via search, while the exact highlight timing remains unverified.
7. Empty query may show blank results or recent items; the recording initially shows an empty result region.
8. Show a clear empty state when no match is found.
9. Escape/outside click closes the dialog (**proposed**).

### 6.11 `SectionDragHandle` and `FloatingSection`

**Observed:** Sections can leave their normal columns and temporarily appear as separate movable cards; other sections shift to fill or occupy positions. The user moves panels back across columns.

**Proposed implementation:**

- Start drag with pointer held on section header.
- Render a `DragPreview` at a higher layer, preserving card width and contents.
- Reserve placeholder or show target outline for potential insertion.
- On release, update `(page, column, order)`.
- Re-render both columns after the state update.
- If dropped outside allowed targets, snap back; optionally support a persistent detached floating state if desired.
- Do not let control interaction (e.g. dragging a slider) accidentally initiate section dragging.

---

## 7. Screen/page examples observed

The original recording demonstrates specific domain-themed settings. These labels are useful as **visual placeholder content** for a faithful recreation; they are **not specifications for implementing game actions**.

| Navigation page | Section titles seen | Example visible UI labels (partial) |
|---|---|---|
| Rage | `Ragebot`, `Silent Aim`, `Targeting`, `Anti Aim` | Enabled, Auto Shoot, Auto Scope, Auto Reload, Force Headshot, Autowall, Min Damage, Hitchance, Target Selection, Max Distance, Use FOV, Draw FOV, FOV Size, Aim Point, Prediction, Prediction Amount, Pitch |
| Legit | `Aim Assist`, `Triggerbot`, `Recoil Control`, `Misc` | Enabled, Draw FOV, FOV, Smoothness, Hitpart, Visible Only, Team Check, Deadzone, Reaction Delay, Magnet Trigger, Magnet FOV, Head Only, No Spread, Quickstop, Jump Check, Flash Check |
| Players | `Chams`, `Radar` and other visual controls | Enabled, Box, Label, Health Bar, Distance, Weapon, Skeleton, Box Style, Max Distance, Show Teammates, Show Enemies, Radar Size, Range, Rotate With Camera |
| Movement | `Movement`, `Bunny Hop` | Speed, Speed Amount, Speed Type, Fly, Fly Speed, No Clip, Enabled, Mode, Auto Strafe, Strafe Strength |
| Settings | `Profiles`, `Theming`, `Menu`, `Autoload` | Configs, Config name, Create, Load, Delete, Overwrite, Theme, Menu Keybind, Watermark, Keybind List, Unload |

`Effects` and `Exploits` are visible as sidebar destinations but their full contents are **not established by the reviewed frames**. Avoid inventing canonical sections for them. An implementation may leave them as blank/placeholder pages until additional evidence is available.

### Page assembly pattern

```text
Page: Rage
  Left column:
    Section: Ragebot
    Section: Targeting
  Right column:
    Section: Silent Aim
    Section: Anti Aim

Page: Legit
  Left column:
    Section: Aim Assist
    Section: Recoil Control
  Right column:
    Section: Triggerbot
    Section: Misc

Page: Movement
  Left column:
    Section: Movement
  Right column:
    Section: Bunny Hop

Page: Settings
  Left column:
    Section: Profiles
    Section: Autoload (lower)
  Right column:
    Section: Theming
    Section: Menu (lower)
```

The Rage page can be reordered during drag operations; the sequence above represents the initial/commonly visible organization, not immutable behavior.

---

## 8. Theme engine

### 8.1 Presets visible in theme selector

The recorded selector lists the following theme names (in displayed order):

1. Blossom
2. Afterglow
3. Frostbite
4. Volt
5. Obsidian
6. Sakura Drift
7. Neon Mirage
8. Copper Dust
9. Abyss
10. Porcelain

**Observed appearance:** `Blossom` is a charcoal + blue combination; `Volt` is a very dark green/bright green treatment; `Porcelain` is a high-key light/white treatment; an orange/brown treatment is shown later in the recording. Do not assume a theme's exact RGB values from its name; presets should be recreated by screenshot sampling and iterative tuning.

### 8.2 Theme object contract (proposed)

```lua
export type UITheme = {
    Background: Color3,
    Tab: Color3,
    Outline: Color3,
    Inline: Color3,
    Text: Color3,
    InactiveText: Color3,
    Accent: Color3,
    Element: Color3,
    Gradient: Color3,
    Shadow: Color3,
    HoveredElement: Color3,
}
```

Use these same keys in the theme customization panel. On theme change, update **all** dependent surface, label, slider, switch, border, shadow, input, and popup colors without rebuilding the entire GUI.

### 8.3 Light/dark support

- Preserve relative contrast instead of blindly inverting colors.
- `Porcelain` should use white/off-white surfaces, dark text, subtle gray strokes, and cool neutral buttons.
- Dark themes can use color-tinted surfaces, but labels must remain legible.
- Icons and muted labels need their own tokens to avoid disappearing against either theme.

### 8.4 Color editing

Clicking a theme swatch opens the **same color picker component** used by ordinary controls. Changing an item should update the interface live. Persist custom theme overrides separately from the selected theme preset (proposed).

---

## 9. Configurations and persistence

### 9.1 Visual flow seen in Settings

1. A large `Configs` list occupies the upper portion of the Profiles section.
2. An item (for example, `test cfg.`) can appear in the list.
3. `Config name` input sits below the list.
4. Full-width buttons appear below: `Create`, `Load`, `Delete`, `Overwrite`.
5. An `Autoload` section sits lower in the same content column.
6. A `Menu` section on the right exposes `Menu Keybind`, `Watermark`, `Keybind List`, and `Unload`.

### 9.2 Recommended UI-only persistence contract

```lua
export type LibraryConfig = {
    version: number,
    name: string,
    selectedPage: string,
    selectedTheme: string,
    themeOverrides: {[string]: Color3}?,
    controls: {[string]: any},
    keybinds: {[string]: {key: string, mode: string}},
    sectionLayout: {[string]: {column: number, order: number}},
    menuVisible: boolean?,
}
```

**Behavior:** `Create` adds a named snapshot; `Load` applies it; `Delete` removes it; `Overwrite` updates the selected snapshot. Store and load only GUI configuration unless the eventual application explicitly supplies its own state adapters.

**Important:** The video does not show the actual storage backend. `DataStoreService`, local JSON, file APIs, or remote persistence are **implementation decisions**, not observed facts.

---

## 10. Interaction behavior and state rules

### 10.1 Selection and overlays

| Event | Expected UI response |
|---|---|
| Click inactive sidebar tab | Switch page; update selected indicator |
| Click active tab | Keep page; no duplicate rendering |
| Click toggle | Flip visual state and dispatch change callback |
| Drag slider | Update track, thumb, and formatted value |
| Click dropdown | Open menu directly above page content |
| Choose dropdown item | Commit selection and close popup |
| Open color swatch | Display color editor at a high overlay layer |
| Change hue/SV/alpha | Update swatch immediately |
| Open keybind menu | Show toggle/hold/reset choices |
| Click sidebar search | Open centered modal, ready for typing |
| Type in search | Filter results live |
| Click result | Navigate to matching control/context |
| Drag section header | Move card with floating preview |
| Release section | Reinsert/reorder or snap back |
| Choose theme | Repaint the entire UI consistently |
| Use profile buttons | Update config list and UI state |

### 10.2 Overlay stacking order (proposed)

```text
Window content           z = 10–19
Dropdowns/keybinds       z = 30–39
Color picker             z = 40–49
Detached drag preview    z = 50–59
Modal dim layer          z = 80
Search modal             z = 81–89
Tooltips                 z = 90+
```

Only one **blocking modal** should be open at once. A dropdown or color picker should not remain stranded when the user switches pages or themes.

### 10.3 Motion (proposed, not measured)

| Effect | Starting recommendation |
|---|---|
| Toggle transition | 0.10–0.15 s |
| Hover fill transition | 0.08–0.12 s |
| Dropdown opening | 0.10–0.16 s |
| Search modal fade | 0.12–0.18 s |
| Drag preview follow | Immediate pointer tracking |
| Drag drop snap | 0.12–0.20 s |
| Theme change | Immediate or 0.10–0.20 s color tween |

The recording suggests restrained transitions; it does **not** establish exact easing curves or durations.

---

## 11. Recommended Luau project architecture

> The project layout below is **proposed** to keep a recreation maintainable. It is not a claim about the original Blossom codebase.

```text
BlossomLibrary/
├── init.luau                   -- create/destroy UI library
├── Core/
│   ├── Store.luau              -- central state and subscriptions
│   ├── Renderer.luau           -- instance creation/update helpers
│   ├── ThemeManager.luau       -- token registry and live theme changes
│   ├── InputManager.luau       -- keyboard, pointer, drag, and hotkeys
│   ├── OverlayManager.luau     -- open/close/position popups
│   ├── SearchIndex.luau        -- searchable control metadata
│   ├── LayoutManager.luau      -- per-page section column/order
│   ├── ConfigManager.luau      -- serialize/restore UI state
│   └── Cleanup.luau            -- disconnect events and destroy refs
├── Components/
│   ├── Window.luau
│   ├── Sidebar.luau
│   ├── NavGroup.luau
│   ├── NavItem.luau
│   ├── Section.luau
│   ├── Toggle.luau
│   ├── Slider.luau
│   ├── Dropdown.luau
│   ├── Keybind.luau
│   ├── ColorPicker.luau
│   ├── TextInput.luau
│   ├── Button.luau
│   ├── ListBox.luau
│   ├── SearchModal.luau
│   └── Tooltip.luau
├── Themes/
│   ├── Blossom.luau
│   ├── Presets.luau
│   └── Tokens.luau
├── Pages/
│   ├── Rage.luau               -- UI demo content only
│   ├── Legit.luau              -- UI demo content only
│   ├── Players.luau            -- UI demo content only
│   ├── Effects.luau            -- placeholder until specified
│   ├── Movement.luau           -- UI demo content only
│   ├── Exploits.luau           -- placeholder until specified
│   └── Settings.luau
└── Demo/
    ├── DemoApp.client.luau
    └── SampleConfiguration.luau
```

### 11.1 Roblox instance mapping

| UI feature | Roblox building blocks |
|---|---|
| Root | `ScreenGui`, `Frame`, `UIScale` |
| Rounded surfaces | `UICorner` |
| Thin borders | `UIStroke` |
| Vertical stacks | `UIListLayout`, `UIPadding` |
| Two columns | Two `Frame` or `ScrollingFrame` containers |
| Text labels | `TextLabel`, optional `TextScaled = false` |
| Click actions | `TextButton` / `ImageButton` |
| Inputs | `TextBox` |
| Scrolling menus | `ScrollingFrame` |
| Animations | `TweenService` |
| Pointer and key state | `UserInputService` |
| Overlay ordering | `ZIndex` plus explicit overlay parent |
| Theme propagation | State subscriptions or a centralized token-update function |

### 11.2 Public library API (suggested, not original)

```lua
local library = BlossomLibrary.new({
    Title = "Blossom",
    Theme = "Blossom",
    Size = UDim2.fromOffset(422, 336),
    Scale = 1,
})

local page = library:AddPage({
    Id = "demo",
    Title = "Demo",
    Group = "General",
    Icon = "settings",
})

local section = page:AddSection({
    Id = "controls",
    Title = "Controls",
    Column = 1,
})

section:AddToggle({
    Id = "demo_enabled",
    Label = "Enabled",
    Default = false,
    OnChanged = function(enabled)
        print("UI state:", enabled) -- demo only
    end,
})

section:AddSlider({
    Id = "demo_amount",
    Label = "Amount",
    Minimum = 0,
    Maximum = 100,
    Step = 1,
    Default = 25,
    OnChanged = function(value)
        print("UI slider:", value) -- demo only
    end,
})
```

**API principle:** Each component owns **rendering and local interaction**, while the central Store owns **canonical values**. Page/section IDs make settings searchable and serializable.

---

## 12. Proposed state shape

```lua
local state = {
    currentPage = "Rage",
    activeTheme = "Blossom",
    scale = 1,
    window = {
        visible = true,
        position = {x = 0.5, y = 0.5},
        size = {width = 422, height = 336},
    },
    search = {
        open = false,
        query = "",
        highlightedResultId = nil,
    },
    popover = {
        kind = nil,        -- "dropdown", "keybind", "colorpicker"
        anchorId = nil,
    },
    draggingSection = nil,
    sectionLayout = {},
    controlValues = {},
    keybindValues = {},
    profileNames = {},
    selectedProfile = nil,
    themeOverrides = {},
}
```

### State invariants

1. Exactly one current page; zero or one blocking modal.
2. Every control has a stable ID and one source of truth.
3. Search result IDs resolve to an actual page/section/control.
4. Every section appears in **one** place per page unless it is actively being dragged.
5. Overlay windows cannot capture input when hidden.
6. Page changes do not reset component values.
7. Config load updates controls, layout, and theme in a predictable order.
8. `Destroy()` cleans every connection and temporary overlay.

---

## 13. Implementation phases

### Phase 1 — Static fidelity

- [ ] Create fixed-size root with centered position and subtle shadow.
- [ ] Create left rail with brand, three named navigation groups, Settings, and bottom search.
- [ ] Create two-column content region and section containers.
- [ ] Reproduce default Blossom palette, corner radii, padding, and text hierarchy.
- [ ] Populate a visual demo page with toggles, sliders, and dropdowns.

### Phase 2 — Component interactions

- [ ] Build reusable Toggle, Slider, Dropdown, Keybind, ColorPicker, TextInput, Button, and ListBox.
- [ ] Add hover, focus, disabled, pressed, and selected states.
- [ ] Ensure all controls handle repeated input without duplicate callbacks.

### Phase 3 — Navigation/search/layout

- [ ] Implement page switching.
- [ ] Register controls in search index; implement modal and filtering.
- [ ] Implement section header dragging between columns.
- [ ] Add popup positioning and dismissal.

### Phase 4 — Themes/profiles

- [ ] Build theme token engine and Settings editor.
- [ ] Add named presets and support both dark and light appearances.
- [ ] Build Profiles list and UI-only create/load/delete/overwrite workflow.
- [ ] Support autoload choice and menu toggles as visual state.

### Phase 5 — Polish/testing

- [ ] Compare screenshots at the **same viewport size/scale** as reference.
- [ ] Check text sizes, panel spacing, and color contrast.
- [ ] Test long dropdown lists, small viewports, theme changes while popups are open.
- [ ] Test independent section reorder, keyboard focus, and cleanup on destroy.

---

## 14. QA and visual acceptance criteria

### Visual

- [ ] Main UI occupies approximately the same on-screen footprint as the recording.
- [ ] Sidebar/content proportions match within a few pixels at reference scale.
- [ ] Brand line, group labels, nav rows, and bottom search align convincingly.
- [ ] Dark colors are subtle but distinct; default accent is cool muted blue.
- [ ] Section headers, control labels, switches, sliders, and numeric values appear at consistent baselines.
- [ ] Two content columns remain independent and do not stretch cards vertically.
- [ ] Dropdown, keybind popover, color picker, and search modal appear above the content without clipping.
- [ ] The `Porcelain` theme visibly changes light/dark surface and text treatment; `Volt` visibly shifts to dark green accents.

### Functional

- [ ] Changing pages keeps current values intact.
- [ ] Search for `speed` returns applicable indexed UI demo controls and their locations.
- [ ] Every popup can close cleanly; opening another popup resolves prior focus.
- [ ] Slider dragging does not drag its parent section.
- [ ] Section dragging updates ordering and does not duplicate sections.
- [ ] Theme changes repaint currently open controls and panels.
- [ ] Profile save/load restores UI values and section layout.
- [ ] Destroying the library leaves no click regions or input listeners active.

### Fidelity constraints

The recreation should **not** claim fidelity for things not visible in the recording: original source layout algorithms, hidden tabs' content, private icons/assets, backend storage, exact fonts, raw theme codes, exact easing/duration, or underlying feature logic. Keep inferred values centralized so they can be tuned later.

---

## 15. Build prompt for a coding assistant

The following prompt can be handed to an implementer together with this file and the original video:

> Build a **Roblox/Luau visual UI library** recreating the Blossom interface described in `blossom-library-ui-recreation.md`. Implement the window, brand/sidebar, categorized navigation, bottom search, independent two-column sections, draggable/reorderable section cards, toggles, sliders, dropdowns, keybind editor, color picker with hue/SV/alpha and animation menu, modal search, theme presets/customization, and UI-only profile management. Match the compact dark-first visual style and relative layout from the screen recording. Use modular components and centralized state, stable IDs, theme tokens, a controlled overlay stack, and complete cleanup. Provide a demo that exercises every component. Treat combat/movement/exploit-related names in the reference strictly as **inert example labels**; implement no gameplay-affecting functionality. Mark screenshot-estimated details as adjustable constants. Include a clear installation guide and basic validation steps.

---

## 16. Final notes and known unknowns

**Well supported by the video:** Blossom branding, navigation labels, two-column layout, compact styling, default blue/dark treatment, extensive theme selector, settings structure, search modal, draggable panels, keybind popup, and color picker.

**Reasonable but not verified:** Exact sizing numbers, HEX palette, font family, original input/callback semantics, persistence backend, drag/drop algorithm, animation speeds, full contents of Effects/Exploits, and whether all popovers close via Escape.

**Best reconstruction strategy:** Match the window shell and typography first, then section layout and interactive components, then overlays, then theme/persistence features. Validate every major milestone against paused frames at the same scale.

**Deliverable definition:** This file is a **recreation specification**, not a compiled or playable `.rbxm`/`.lua` implementation. It is intentionally detailed enough to guide implementation without claiming access to the original library's source code.
