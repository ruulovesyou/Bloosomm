# Blossom UI Library — agent instructions

## Objective and boundary
Recreate the compact Blossom interface with native Roblox UI instances and reusable Luau APIs. The source specification is `reference/blossom-library-ui-recreation.md`; its full-build prompt is reference material, not authorization to expand this phase.

The user expanded scope to the complete library and removed Roblox Studio testing from delivery requirements. Implement all specified interface features, finish available headless verification, and keep documentation current. The former first-50% boundary and Gemini-only ownership no longer apply.

## Stack and architecture
- Roblox Luau, native Instances, TweenService and UserInputService; client-only under PlayerGui. No external runtime dependencies, executors, HTTP loaders, remotes, or gameplay changes.
- Rojo layout: `src/Blossom/init.luau` maps to the Blossom ModuleScript in ReplicatedStorage; its folders are children. Demo LocalScript maps to StarterPlayerScripts.
- Core modules own canonical values, scoped resource cleanup, input routing, rendering helpers, theme bindings, and a single transient popup. Components render and subscribe; they never own duplicate canonical values.
- Dependency direction: entry point -> window/page/section/components -> Core -> Themes/pure utilities. Core never requires components. Demo requires only the public library.
- Stable control IDs are unique across a library instance; section IDs are unique per page; page IDs are unique. Register metadata including label, type, page and section for future search.
- One library owns its ScreenGui and resources; Destroy is idempotent. No untracked global input connections or per-frame idle loops.
- InputObject.Position and GuiObject.AbsolutePosition use the same inset-relative coordinates. Compare directly; scale local popup positions once. Ignore additional pointers during an active drag, and restore column scrolling on every cancellation path.

## Conventions and standards
- PascalCase module filenames/public methods/options, camelCase locals, descriptive stable snake_case IDs.
- Native Roblox types, `--!strict` for pure logic, `--!nonstrict` only where dynamic Instance construction/object composition needs it; never claim full static typing without a Roblox-aware check.
- Validate public options before constructing controls. Programmatic SetValue uses the same normalization and Store path as interaction. Unchanged values do not dispatch; callback failures must not break other subscribers.
- Scope connections, theme bindings and active tweens. Preserve values on page changes; close overlays and cancel drags on hide/page change/destroy.
- Tests should exercise meaningful state, normalization, serialization and lifecycle behavior. Use headless Luau, static analysis and package checks. Roblox Studio testing is excluded by user request; do not claim native execution or pixel-perfect verification.
- Update PROGRESS.md and HANDOFF.md at every stable milestone and record failures immediately. Commit stable milestones if Git works; never overwrite unrelated work.

## Design requirements
- Estimated baseline: 422 x 336, 103px rail, 8px gutters, small Gotham labels, subtle warm charcoal surfaces and muted blue accent. Constants live in Themes/Tokens.luau.
- One UIScale scales the whole window including popups. Independent scrolling columns; content-sized cards. Use no external image assets; small geometric markers are approximations.
- Dropdowns use a higher overlay layer, outside-click/Escape dismissal, bounded scroll and upward placement when needed. Only one popup at once.
- Support mouse/touch, visible hover/focus/pressed/disabled states, reduced motion option and explicit scale. Compact reference scale is desktop-oriented; do not claim mobile accessibility without device testing.
- Recorded combat/movement labels are inert UI examples only. Effects/Exploits content is unknown. Do not invent canonical content.
- Implement search, keybinds, color picker/animations, theme presets/editor, profiles with validated JSON and injectable storage, and section reorder/detach. Keep all sample behavior UI-only. Default profile storage is session-local; export/import or a host adapter provides durable storage without executor APIs.

## Future agents
Run `tools/verify.ps1`. Respect public APIs and Store ownership. Update demo, tests and docs together. The repository must be sufficient without chat history. Studio testing is not a completion gate. Read HANDOFF.md for the current implementation state.
