import SwiftUI
import AppKit
import BetterTabCore

/// The menu-bar popover, restyled as a native macOS surface: vibrancy
/// background, a grouped shortcuts list with system selection, and a
/// System-Settings-style +/− control.
struct RootView: View {
    @EnvironmentObject var model: BindingsModel
    @State private var selected: AppBinding?
    @State private var adding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().padding(.bottom, 10)

            Text("Shortcuts")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 18)
                .padding(.bottom, 6)

            card
                .padding(.horizontal, 14)

            toolbar
                .padding(.horizontal, 16)
                .padding(.top, 7)

            if adding {
                AddBindingView(onDone: {
                    withAnimation(.easeOut(duration: 0.18)) { adding = false }
                })
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.bottom, 12)
        .frame(width: 340)
        .background(VisualEffectBackground().ignoresSafeArea())
        .onAppear { model.errorMessage = nil }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            appMark
            VStack(alignment: .leading, spacing: 1) {
                Text("BetterTab")
                    .font(.system(size: 14, weight: .semibold))
                Text("Jump to any app with a keystroke")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("Quit BetterTab") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var appMark: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 30, height: 30)
            .overlay(
                Image(systemName: "command")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .shadow(color: Color.accentColor.opacity(0.35), radius: 4, y: 1)
    }

    // MARK: List card

    private var card: some View {
        Group {
            if model.bindings.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.bindings.enumerated()), id: \.element) { index, binding in
                        BindingRow(
                            binding: binding,
                            isSelected: selected == binding,
                            onSelect: { selected = binding }
                        )
                        if index < model.bindings.count - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "keyboard")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No shortcuts yet")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
    }

    // MARK: +/− toolbar

    private var toolbar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    model.errorMessage = nil
                    withAnimation(.easeOut(duration: 0.18)) { adding = true }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .frame(width: 24, height: 19)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Add shortcut")

                Divider().frame(height: 13)

                Button {
                    if let selected { withAnimation(.easeOut(duration: 0.16)) { model.remove(selected) } }
                    selected = nil
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .medium))
                        .frame(width: 24, height: 19)
                        .contentShape(Rectangle())
                        .foregroundStyle(selected == nil ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
                }
                .buttonStyle(.plain)
                .disabled(selected == nil)
                .help("Remove selected shortcut")
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            )

            Spacer()
        }
    }
}
