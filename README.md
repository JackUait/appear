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

## Install

**Requirements:** macOS 15 (Sequoia) or later.

Download and install with a single command — it fetches the latest release,
clears the download quarantine so it opens without a Gatekeeper prompt, and
launches it:

```bash
curl -L https://github.com/JackUait/appear/releases/latest/download/Appear.zip -o /tmp/Appear.zip \
  && ditto -x -k /tmp/Appear.zip /Applications \
  && xattr -dr com.apple.quarantine /Applications/Appear.app \
  && open /Applications/Appear.app
```

Prefer the GUI? Download **[Appear.zip](https://github.com/JackUait/appear/releases/latest/download/Appear.zip)**,
unzip it, drag **Appear** to your Applications folder, then **right-click ▸ Open**
the first time (Gatekeeper will let you confirm).

The Appear logo appears in the menu bar (no Dock icon). Multi-key chord
shortcuts (e.g. `L+R+G+N+M`) need Accessibility access — Appear prompts you and
links straight to the setting.

> **Note:** Appear isn't notarized by Apple yet, so a plain double-click shows a
> Gatekeeper warning. The install command above clears the quarantine flag so it
> opens cleanly. A fully notarized build (double-click, no warnings) is planned.

## Run from source

```bash
swift run Appear
```

The Appear logo appears in the menu bar (no Dock icon). Press **⌃⌥S** to jump to
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
