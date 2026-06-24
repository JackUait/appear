import SwiftUI
import AppKit

/// The Appear logo, loaded once from the bundled resource.
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
}

/// The app's logo at a given height. Falls back to a gradient command tile if
/// the asset can't be found (e.g. a bare `swift run` without the resource bundle).
struct BrandLogo: View {
    var height: CGFloat = 30

    var body: some View {
        if let logo = Brand.logo {
            Image(nsImage: logo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: height)
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
