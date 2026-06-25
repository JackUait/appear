#!/usr/bin/env bash
#
# Build a distributable release of Appear: assemble the .app, optionally sign it
# with a Developer ID + notarize + staple, then zip it for upload.
#
# Plain (no Apple Developer account):
#   scripts/release.sh                       # -> dist/Appear-<version>.zip (ad-hoc signed)
#
# Notarized (needs an Apple Developer account):
#   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE="appear-notary" \
#   scripts/release.sh
#
# (Create NOTARY_PROFILE once with:
#   xcrun notarytool store-credentials appear-notary \
#     --apple-id you@example.com --team-id TEAMID --password app-specific-pw)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
cd "$ROOT"

VERSION="${VERSION:-1.0.0}"
APP_NAME="Appear"
APP="dist/$APP_NAME.app"
ZIP="dist/$APP_NAME-$VERSION.zip"

# 1. Assemble the .app (ad-hoc signed by default).
VERSION="$VERSION" bash "$SCRIPT_DIR/package-app.sh"

# 2. If a Developer ID is provided, re-sign with hardened runtime and notarize.
if [[ -n "${DEVELOPER_ID:-}" ]]; then
  echo "==> Signing with Developer ID + hardened runtime..."
  codesign --force --deep --options runtime --timestamp \
    --sign "$DEVELOPER_ID" "$APP"
  codesign --verify --strict --verbose=2 "$APP"

  echo "==> Zipping for notarization..."
  ditto -c -k --keepParent "$APP" "$ZIP"

  if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    echo "==> Submitting to Apple notary service..."
    xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
    echo "==> Stapling ticket..."
    xcrun stapler staple "$APP"
    rm -f "$ZIP"
    ditto -c -k --keepParent "$APP" "$ZIP"   # re-zip the stapled app
    echo "==> Notarized + stapled."
  else
    echo "!! DEVELOPER_ID set but NOTARY_PROFILE missing — signed but NOT notarized."
  fi
else
  echo "==> No DEVELOPER_ID set; shipping ad-hoc signed (users strip quarantine on install)."
  ditto -c -k --keepParent "$APP" "$ZIP"
fi

echo ""
echo "==> Release artifact: $ZIP ($(du -h "$ZIP" | cut -f1))"
