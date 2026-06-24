import SwiftUI
import AppearCore

/// A searchable application chooser. Collapsed, it shows the selected app (icon
/// + name); tapped, it expands into a focused search field over a filtered,
/// icon-rich list — far friendlier than a flat alphabetical menu of every app.
///
/// The list expands inline rather than in a floating popover: a child popover
/// inside a menu-bar popover steals keyboard focus, which would break the search
/// field. The host popover grows to fit, so the list stays fully visible.
struct AppPicker: View {
    let apps: [InstalledApp]
    @Binding var bundleID: String?

    /// Cap on the expanded list height.
    var listMaxHeight: CGFloat = 260

    /// Notifies the host when the list expands/collapses, so it can grow to fit.
    var onExpandedChange: (Bool) -> Void = { _ in }

    @State private var expanded = false
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var filtered: [InstalledApp] {
        guard !query.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            trigger
            if expanded {
                Divider()
                searchField
                Divider()
                list
            }
        }
        .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.quaternary))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .animation(.snappy(duration: 0.18), value: expanded)
        .onChange(of: expanded) { _, isOpen in onExpandedChange(isOpen) }
    }

    private var trigger: some View {
        Button(action: toggle) {
            HStack(spacing: 7) {
                if let bundleID {
                    AppIcon(bundleID: bundleID, size: 17)
                    Text(AppCatalog.name(forBundleID: bundleID)).lineLimit(1)
                } else {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    Text("Choose an app").foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                Image(systemName: expanded ? "chevron.up" : "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
            }
            .font(.system(size: 12))
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 30)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11)).foregroundStyle(.secondary)
            TextField("Search apps", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($searchFocused)
                .onSubmit(selectFirst)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filtered.isEmpty {
                    Text("No apps found")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12).padding(.vertical, 9)
                } else {
                    ForEach(filtered) { app in
                        AppRow(app: app, selected: app.bundleID == bundleID) { select(app) }
                    }
                }
            }
            .padding(5)
        }
        .frame(maxHeight: listMaxHeight)
    }

    private func toggle() {
        expanded.toggle()
        if expanded { DispatchQueue.main.async { searchFocused = true } }
        else { query = "" }
    }

    private func selectFirst() {
        if let first = filtered.first { select(first) }
    }

    private func select(_ app: InstalledApp) {
        bundleID = app.bundleID
        query = ""
        searchFocused = false
        expanded = false
    }
}

/// One selectable app row with hover feedback.
private struct AppRow: View {
    let app: InstalledApp
    let selected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                AppIcon(bundleID: app.bundleID, size: 18)
                Text(app.name).font(.system(size: 12)).lineLimit(1)
                Spacer(minLength: 6)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(hovering ? AnyShapeStyle(.selection) : AnyShapeStyle(.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
