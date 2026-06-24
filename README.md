# better-tab

A macOS menu-bar app: bind global keyboard shortcuts to applications and press
one to jump to (activate/launch) that app.

Built entirely from native macOS components. Two surfaces:

- **Menu-bar popover** — a native `List` that doubles as a launcher: click any
  row to jump to that app. "Edit Shortcuts…" opens the window.
- **Standalone window** — a native `Table` (Application · Shortcut) with a
  toolbar +/− control and a grouped `Form` sheet for adding a binding (checkbox
  modifiers, `Picker`s for the key and app, a live preview). While the window is
  open the app is a regular Dock app; it returns to a menu-bar agent on close.

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
