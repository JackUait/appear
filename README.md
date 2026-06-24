# better-tab

A macOS menu-bar app: bind global keyboard shortcuts to applications and press
one to jump to (activate/launch) that app.

An Airbnb-inspired interface (warm white surfaces, the coral accent, rounded
type, soft shadows) across two surfaces, both fully editable:

- **Menu-bar popover** — a compact list. Tap a row to jump to that app; hover to
  reveal edit/delete; add or edit a shortcut **inline** without leaving the
  popover (circular modifier toggles, key/app pickers, a coral "Add" pill).
- **Standalone window** — a roomy view of shortcut cards with the same inline
  editor. While it's open the app is a regular Dock app; it returns to a
  menu-bar agent on close.

Bindings persist across launches; a fresh install seeds **⌃⌥S → Safari** and
**⌃⌥F → Finder**.

## Run from source

```bash
swift run BetterTab
```

A ⌘ icon appears in the menu bar (no Dock icon). Press **⌃⌥S** to jump to
Safari. Stop with Ctrl-C or the **Quit BetterTab** menu item.

## Test

```bash
swift test
```

## Package as a .app

Assembles a signed `dist/BetterTab.app` (menu-bar agent via `LSUIElement`,
ad-hoc code signature):

```bash
scripts/package-app.sh           # release build
open dist/BetterTab.app          # launch it

CONFIG=debug scripts/package-app.sh   # debug build instead
```

Override metadata with `BUNDLE_ID`, `VERSION`, `BUILD`, `MIN_MACOS` env vars.
