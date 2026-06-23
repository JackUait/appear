import SwiftUI

/// The macOS icon for an app, resolved by bundle identifier, in a squircle.
struct AppIcon: View {
    let bundleID: String
    var size: CGFloat = 30

    var body: some View {
        Group {
            if let image = AppCatalog.icon(forBundleID: bundleID) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        Image(systemName: "app.dashed")
                            .foregroundStyle(Theme.textFaint)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
    }
}
