import SwiftUI

/// The macOS icon for an app, resolved by bundle identifier.
struct AppIcon: View {
    let bundleID: String
    var size: CGFloat = 28

    var body: some View {
        Group {
            if let image = AppCatalog.icon(forBundleID: bundleID) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .overlay(
                        Image(systemName: "app.dashed")
                            .foregroundStyle(.tertiary)
                    )
            }
        }
        .frame(width: size, height: size)
    }
}
