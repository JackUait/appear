# better-tab

A bare-bones macOS menu-bar app: bind a global keyboard shortcut to an
application and press it to jump to (activate/launch) that app. Ships with one
live binding — **⌃⌥S → Safari**.

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
