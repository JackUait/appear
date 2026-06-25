<p align="center">
  <img src="Assets/AppearBrand.png" alt="Appear" width="360">
</p>

A macOS menu-bar app: bind global keyboard shortcuts to applications and press
one to jump to (activate/launch) that app.

A refined, modern macOS interface following Apple's guidelines — vibrancy
materials, SF Pro, the system accent color, light/dark adaptive — across two
surfaces:

- **Menu-bar popover** — a vibrant compact list. Tap a row to jump to that app;
  hover to reveal edit/delete; add or edit a shortcut **inline** without leaving
  the popover (native modifier toggles, key/app popups).
- **Standalone window** — a `NavigationStack` with a unified toolbar, search,
  and an inset list. Add/edit via a grouped `Form` sheet; right-click for
  context actions. While it's open the app is a regular Dock app; it returns to
  a menu-bar agent on close.

Bindings persist across launches; a fresh install seeds **⌃⌥S → Safari** and
**⌃⌥F → Finder**.

## Run from source

```bash
swift run Appear
```

A ⌘ icon appears in the menu bar (no Dock icon). Press **⌃⌥S** to jump to
Safari. Stop with Ctrl-C or the **Quit Appear** menu item.

## Test

```bash
swift test
```

## Package as a .app

Assembles a signed `dist/Appear.app` (menu-bar agent via `LSUIElement`,
ad-hoc code signature):

```bash
scripts/package-app.sh           # release build
open dist/Appear.app          # launch it

CONFIG=debug scripts/package-app.sh   # debug build instead
```

Override metadata with `BUNDLE_ID`, `VERSION`, `BUILD`, `MIN_MACOS` env vars.
