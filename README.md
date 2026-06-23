# better-tab

A macOS menu-bar app: bind global keyboard shortcuts to applications and press
one to jump to (activate/launch) that app.

Click the menu-bar icon to open a dark "Night Console" popover where every
shortcut is a backlit keycap. Add a binding by toggling modifier keycaps,
tapping a key on the mini QWERTY keyboard, and picking a target app. Bindings
persist across launches; a fresh install seeds **⌃⌥S → Safari** and
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
