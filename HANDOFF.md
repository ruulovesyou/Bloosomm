# Handoff to Gemini 4 Argon / Google Antigravity

## Current state
M0 documentation checkpoint, 2026-11-16. Repository was empty. First agent is building the explicitly bounded foundation; implementation has not started at this checkpoint. Read AGENTS.md, PROGRESS.md and the complete local reference.

## Files at this checkpoint
- `AGENTS.md`: objective, architecture, naming, development/design rules and phase boundary.
- `PROGRESS.md`: detailed scope, milestones, verification and unresolved limitations.
- `HANDOFF.md`: this recovery document.
- `reference/blossom-library-ui-recreation.md`: exact copy of supplied blueprint.

## Planned module ownership and API
- `src/Blossom/init.luau`: `new`, `AddPage`, `SelectPage`, `GetValue`, `SetValue`, `GetControls`, `SetTheme`, `SetScale`, `SetVisible`, `Destroy`.
- Core: Cleanup (scoped disposal), Store (canonical values/subscriptions), Value (pure validation/snap), Renderer (Instance helpers/motion), ThemeManager (token bindings), InputManager (one active pointer gesture), OverlayManager (one dismissible popup).
- Components: Window, Sidebar, Page, Section; Toggle/Slider/Dropdown/Button/TextInput. Pages own sections, sections own controls. `page:AddSection`, `section:AddToggle/AddSlider/AddDropdown/AddButton/AddTextInput`.
- Themes: Blossom colors and Tokens dimensions/motion. Demo: only public API, inert callbacks.
- Controls return handles with `GetValue`, `SetValue`, `SetDisabled`; lifetime owned by library in phase one. Exact implemented contract will replace this plan.

## Decisions
Native client UI; no external runtime dependencies or game effects. Central Store owns values, registry owns metadata. Per-window cleanup and a single active popup. Two independent column ScrollingFrames. Only whole-window dragging in this phase. Reference section dragging/search/profiles/color pickers are second-agent work. Default reference-scale typography is compact; configurable UIScale provides a larger alternative.

## Exact stopping/recovery point
Documentation created before implementation. Next: implement and verify pure core Store/Value/Cleanup, then rendering infrastructure. No component work is complete yet.

## Known integration issues
No Studio or Luau tooling detected at intake; do not equate headless checks with native rendering/input verification. Original recording exists outside repo, but only the blueprint is currently repository-contained. A local reference frame may be added if extraction tools are available.

## Remaining sequence
1. Finish foundation milestones in PROGRESS.md.
2. Package demo with Rojo project and manual import/build instructions.
3. Run available tests; log unavailable checks precisely.
4. Review/fix critical foundation issues, update this document with exact APIs and inventory, commit, stop.
5. Second agent: validate foundation in Studio first, then implement search using registry metadata before advanced controls/layout/persistence.
