import SwiftUI
import AppKit

/// The Appear logo, loaded once and downsampled on demand.
enum Brand {
    static let logo: NSImage? = {
        // Loaded from the packaged app's Contents/Resources (placed there by
        // scripts/package-app.sh). Under a bare `swift run` it's absent, so the
        // brand mark falls back to the command tile — fine for development.
        guard let url = Bundle.main.url(forResource: "AppearLogo", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }()

    private static var cache: [Int: NSImage] = [:]

    /// A copy of the logo high-quality-downsampled to exactly `height` points at
    /// `scale` (e.g. Retina 2×). Pre-sizing to the target avoids SwiftUI's
    /// single-pass downscale of the full-resolution image, which aliases the
    /// rounded edges and looks harsh.
    static func logo(height: CGFloat, scale: CGFloat) -> NSImage? {
        guard let logo else { return nil }
        let pixelHeight = max(1, Int((height * scale).rounded()))
        if let cached = cache[pixelHeight] { return cached }

        let aspect = logo.size.width / max(logo.size.height, 1)
        let pointSize = NSSize(width: height * aspect, height: height)
        let targetW = pointSize.width * scale
        let targetH = pointSize.height * scale

        // Progressively halve the full-resolution image toward the target. Each
        // 2:1 step averages neighbouring pixels, so the final edges come out
        // smooth instead of the harsh aliasing a single big downscale produces.
        var stage = logo
        var w = logo.size.width
        var h = logo.size.height
        while w > targetW * 2, h > targetH * 2 {
            w /= 2; h /= 2
            stage = redraw(stage, pixelWidth: Int(w.rounded()), pixelHeight: Int(h.rounded()),
                           pointSize: NSSize(width: w, height: h))
        }

        let result = redraw(stage, pixelWidth: Int(targetW.rounded()), pixelHeight: Int(targetH.rounded()),
                            pointSize: pointSize)
        cache[pixelHeight] = result
        return result
    }

    /// Draws `image` into a fresh high-interpolation bitmap of the given pixel
    /// size, returning an `NSImage` whose point size is `pointSize`.
    private static func redraw(_ image: NSImage, pixelWidth: Int, pixelHeight: Int,
                               pointSize: NSSize) -> NSImage {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: max(1, pixelWidth), pixelsHigh: max(1, pixelHeight),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return image }
        rep.size = pointSize

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: pointSize),
                   from: .zero, operation: .sourceOver, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()

        let result = NSImage(size: pointSize)
        result.addRepresentation(rep)
        return result
    }
}

/// The app's logo at a given height. Falls back to a gradient command tile if
/// the asset can't be found (e.g. a bare `swift run` without the resource).
struct BrandLogo: View {
    var height: CGFloat = 30
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        if let logo = Brand.logo(height: height, scale: max(displayScale, 2)) {
            Image(nsImage: logo)
                .interpolation(.high)
                .antialiased(true)
        } else {
            RoundedRectangle(cornerRadius: height * 0.27, style: .continuous)
                .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.78)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: height, height: height)
                .overlay(
                    Image(systemName: "command")
                        .font(.system(size: height * 0.46, weight: .semibold))
                        .foregroundStyle(.white)
                )
        }
    }
}
