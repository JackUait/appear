#!/usr/bin/env bash
# Regenerate Assets/Appear.icns from Assets/AppearLogo.png.
# The logo is non-square with a transparent background; we center it on a
# square transparent canvas (with a small margin), then build the iconset.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SRC="$ROOT/Assets/AppearLogo.png"
MASTER="$(mktemp -d)/master.png"
ICONSET="$(mktemp -d)/Appear.iconset"
mkdir -p "$ICONSET"

# Render a 1024x1024 transparent master with the logo centered (88% fit).
swift - "$SRC" "$MASTER" <<'SWIFT'
import AppKit
let args = CommandLine.arguments
let src = NSImage(contentsOfFile: args[1])!
let side: CGFloat = 1024
let out = NSImage(size: NSSize(width: side, height: side))
out.lockFocus()
NSColor.clear.set()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: side, height: side)).fill()
let margin = side * 0.06
let avail = side - margin * 2
let s = src.size
let scale = min(avail / s.width, avail / s.height)
let w = s.width * scale, h = s.height * scale
src.draw(in: NSRect(x: (side - w) / 2, y: (side - h) / 2, width: w, height: h),
         from: .zero, operation: .sourceOver, fraction: 1.0)
out.unlockFocus()
let rep = NSBitmapImageRep(data: out.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
SWIFT

for size in 16 32 128 256 512; do
  sips -z "$size" "$size"     "$MASTER" --out "$ICONSET/icon_${size}x${size}.png"    >/dev/null
  sips -z $((size*2)) $((size*2)) "$MASTER" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$ROOT/Assets/Appear.icns"
echo "wrote $ROOT/Assets/Appear.icns ($(du -h "$ROOT/Assets/Appear.icns" | cut -f1))"
