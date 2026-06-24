#!/usr/bin/env bash
#
# Package the Appear SwiftPM executable into a runnable, ad-hoc-signed .app
# bundle. SwiftPM only produces a bare binary, so we assemble the bundle by hand:
# a Contents/MacOS executable + an Info.plist (with LSUIElement so it runs as a
# menu-bar agent with no Dock icon) + an ad-hoc code signature so macOS will
# launch it without Gatekeeper blocking.
#
# Usage:
#   scripts/package-app.sh            # release build -> dist/Appear.app
#   CONFIG=debug scripts/package-app.sh
#
# Override metadata via env vars: BUNDLE_ID, VERSION, BUILD, MIN_MACOS.

set -euo pipefail

# --- configuration ---------------------------------------------------------
APP_NAME="Appear"
BUNDLE_ID="${BUNDLE_ID:-io.dodobrands.appear}"
VERSION="${VERSION:-1.0}"
BUILD="${BUILD:-1}"
MIN_MACOS="${MIN_MACOS:-15.0}"
CONFIG="${CONFIG:-release}"

# --- resolve paths ---------------------------------------------------------
# Repo root = parent of this script's directory, regardless of CWD.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
cd "$REPO_ROOT"

DIST_DIR="$REPO_ROOT/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"

# --- build -----------------------------------------------------------------
echo "==> Building $APP_NAME ($CONFIG)..."
swift build -c "$CONFIG" --product "$APP_NAME"
BINARY="$(swift build -c "$CONFIG" --product "$APP_NAME" --show-bin-path)/$APP_NAME"

if [[ ! -x "$BINARY" ]]; then
  echo "error: built binary not found at $BINARY" >&2
  exit 1
fi

# --- assemble bundle -------------------------------------------------------
echo "==> Assembling $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BINARY" "$CONTENTS/MacOS/$APP_NAME"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>      <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>$VERSION</string>
    <key>CFBundleVersion</key>         <string>$BUILD</string>
    <key>LSMinimumSystemVersion</key>  <string>$MIN_MACOS</string>
    <key>LSUIElement</key>             <true/>
</dict>
</plist>
PLIST

# --- sign ------------------------------------------------------------------
# Ad-hoc signature ("-") gives the app a stable identity so macOS launches it
# and so per-app permission grants stick across runs.
echo "==> Ad-hoc signing..."
codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --verbose "$APP_BUNDLE"

echo ""
echo "==> Done: $APP_BUNDLE"
echo "    Launch with:  open \"$APP_BUNDLE\""
echo "    (Menu-bar agent — look for the ⌘ icon, no Dock icon.)"
