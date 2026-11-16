# Native Roblox acceptance — NOT RUN

Run this before extending the foundation. No Roblox Studio installation/runtime was available to the first agent. Record pass/fail, viewport, scale, device, and screenshots here; never infer a pass from compilation.

1. Build/open `build/BlossomSmokeTests.rbxlx` and press Play. Output must show the single `PASS Blossom Studio smoke...` line with no errors. This covers API construction, values, navigation, computed layout sizes, theme, disabled state, visibility and destruction. It does not generate pointer events.
2. Open `build/BlossomDemo.rbxlx`, Play at 1280×720, scale 1. Confirm 422×336 window, 103px rail, two independent columns, no vertical card stretching, no overlapping text, and fixed sidebar while each column scrolls. Compare with `reference/recording-00m02s.png`; it is the original, not a rendered result.
3. Click each navigation page; exactly one page visible, active row correct. Effects/Exploits blank by design. Change Rage values, switch away/back: retain values and scroll position. Test repeated active-page clicks.
4. Toggle repeatedly; knob position and value agree. Force Headshot remains disabled. Settings → Disable input makes the name field noneditable and restores it when unchecked. Check no duplicate callbacks in Output.
5. Drag sliders to both ends and beyond with mouse; release outside window. Values clamp/snap, window stays still. Scroll a column while idle; slider touch drag must suspend its own column scrolling and restore it on release/cancel. Test a second unrelated touch and focus loss. Select a slider using native GUI navigation, then try arrows/D-pad.
6. Open Aim Point; scroll all eight options. Select each; label updates. Close using Escape, outside click, same trigger, page change, scale change and theme change. Open another dropdown and confirm first is gone. Drag window to viewport bottom/right; menu must open upward or clamp and remain above cards without clipping. Scroll the anchor while open: close rather than strand the menu.
7. Settings → Demo name: type, blur, press Enter, paste >40 Unicode characters, test IME, and test disabling with uncommitted text. Verify changed callback once per changed commit and Submitted only on Enter. Test callback updates Last action. Reset demo clears name/status and restores Min Damage.
8. Drag via Blossom brand strip using mouse/touch; controls must not start window drag. Release outside, alt-tab mid-drag, resize viewport. Check bounds and absence of stuck drag. At scale 1.25/1.5 test popup placement, slider pointer alignment and drag deltas again. UI scale dropdown changes only UI.
9. Preview warm accent / Restore blue accent; selected navigation, toggle, slider, section markers and new dropdown selection colors update consistently. Repeat rapidly to expose competing tween/binding issues. Instantiate with ReducedMotion=true: no delayed transitions.
10. Hover/press/release buttons and dropdowns; no layout movement. Native selected-object highlight stays visible. Test text focus outline. Full gamepad focus trapping is not claimed.
11. Unload with an open dropdown, focused textbox and (separately) active drag. Window disappears; no listeners/click regions remain. Recreate/destroy 20 times in a client test session; inspect Output and memory for retained GUI/tween/input objects. Destroy twice must be safe. Test OnChanged calling Destroy.
12. Test narrow/mobile viewports and touch emulator. Current fixed two-column design may clip if larger than viewport; record any required adaptive-fit work, do not silently claim mobile support.

## Results

Pending Studio. No visual/native passes recorded.
