# Blossom foundation progress

Updated 2026-11-16. **Foundation scope implemented; stopped at the handoff boundary.** Approximately 50% means the agreed feature split, not measured effort. Native Studio acceptance is still pending.

## Milestones

- [x] M0: full reference read, instructions/progress/handoff created, reference copied, Git initialized.
- [x] M1: pure core/tests and shared rendering/theme/input/popup infrastructure.
- [x] M2: window, grouped navigation, pages, independent columns/sections.
- [x] M3: five reusable controls and interaction states.
- [x] M4: demo, model/demo/smoke builds, tests and dependency checks.
- [x] M5: foundation review/fixes and self-contained final handoff. Final commit is the last delivery operation.

## Completed implementation

- [x] Modular native client Luau library; no runtime dependencies or game effects.
- [x] Centered 422×336 window, branding/shadow, 103px rail and selected navigation.
- [x] Retained pages, independent scrolling columns and content-sized sections.
- [x] Central geometry/type/motion/color tokens and partial live theme overrides.
- [x] Stable registration/metadata, canonical values and protected change callbacks.
- [x] Toggle, slider, scrollable single-select dropdown, button, text input.
- [x] Hover/press/selection/disabled states, text focus outline, reduced motion.
- [x] Bounded branding-strip window drag with mouse/touch and cancellation.
- [x] Slider clamp/snap/units, drag and selected arrow/D-pad path.
- [x] Single layered popup with bounded/upward placement and outside/Escape/lifecycle dismissal.
- [x] Unicode text limit, blur commit and Enter submission.
- [x] Explicit UIScale, hide/show and idempotent scoped cleanup.
- [x] Inert demo with seven recorded destinations and all five control types.
- [x] Installation/API guide, reproducible runner, native smoke source and manual QA.

Checked means implemented, **not native interaction or visual acceptance**.

## Verification actually performed

Final `tools/verify.ps1` passes with official Luau 0.747 / Rojo 7.7.1:

| Check | Result |
| --- | --- |
| Source/demo/test compile | 23 Luau files pass |
| Pure strict analysis | Cleanup, Store, Value pass |
| Headless core tests | 8 pass |
| Library model build | build/Blossom.rbxmx passes |
| Demo place build | build/BlossomDemo.rbxlx passes |
| Native smoke place build | build/BlossomSmokeTests.rbxlx passes |
| XML dependencies | Each artifact: 20 modules, 42 resolved edges, no cycles, correct client entry points |
| Original-video review | 2-second frame extracted/inspected; no implementation screenshot comparison |
| Studio smoke execution | **Not run** — native runtime unavailable |
| Native pointer/focus/device/manual QA | **Not run** — checklist supplied |

Tests cover slider snap/bounds/invalid/extreme numbers, option validation, UTF-8 text, canonical values/snapshot isolation, unchanged callback suppression, unsubscribe, reentrant delivery, callback failure isolation and idempotent reverse cleanup. Intentional callback-error output is expected in the passing suite.

## Errors found and resolved

- Initial missing-module test established the test-first baseline; pure modules implemented and tests pass.
- Store type inference errors: explicit self types; strict analysis passes.
- Compiler invocation treated null as filename: corrected to --null; all source compiles.
- Double GUI-inset subtraction: removed after checking Roblox's shared coordinate documentation.
- Competing navigation theme bindings: one dynamic writer per property.
- Stale notifications after reentrant Store updates: suppress superseded delivery; regression passes.
- Textbox callback could destroy library before a later read: added post-callback lifetime guard.
- Touch slider could compete with scroll: suspend/restore owning column during gesture.
- Secondary pointer/callback cancellation could leave scroll state wrong: ignore extra pointers; Begin returns whether the gesture survives its initial callback.
- XML checker assumed ProtectedString while Rojo emits string Source: accept both; all package checks pass.
- Git sandbox index denial resolved with approved escalation. Missing author identity handled with command-local Codex agent identity, without changing user Git configuration.

## Pending native acceptance / limitations

- [ ] Execute Studio smoke and full manual checklist; fix foundation defects before advanced work.
- [ ] Screenshot fidelity, text clipping, AutomaticSize and safe-inset pointer alignment at multiple scales.
- [ ] Touch/focus-loss/callback destruction and repeated create/destroy in engine.
- [ ] Full mobile/gamepad accessibility/focus flow. Compact default is desktop-oriented; fixed window may clip on small viewports.
- [ ] Whole-library Roblox-aware type analysis; current dynamic engine modules are nonstrict.

No confirmed unresolved defect remains in executed pure tests/build checks. Native correctness and visual fidelity are not established.

## Second-agent feature scope

- [ ] Search index/modal/filter/reveal — exact next implementation task in HANDOFF.md.
- [ ] Keybind editor/modes and ListBox.
- [ ] HSV/alpha color picker and animation choices.
- [ ] Theme presets/customization including Porcelain/Volt.
- [ ] UI-only profiles/config adapter; choose persistence separately.
- [ ] Detachable/reorderable sections with layout state.
- [ ] Full Settings and final visual/device acceptance.

Search is visibly disabled as Search (soon). Effects/Exploits are empty because reference contents are unknown. No remaining-half feature has been started.

## Recovery and skills

Docs were created before implementation and refreshed at core, component, integration and final milestones. Initial docs: `1bfa32a`; foundation: `67436e3`; use git log -1 for final review/handoff commit. Branch master, no remote/push. Generated builds/tools are ignored and reproducible. HANDOFF lists every file/API/decision and next step.

Actually loaded/applied: ponytail, superpowers (execution/delivery and TDD references), ui-ux-pro-max, ecc:coding-standards. The general design search's unrelated marketing result was rejected; targeted focus guidance was applied while the user's blueprint controlled design.
