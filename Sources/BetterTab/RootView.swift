import SwiftUI
import AppKit
import BetterTabCore

/// The menu-bar popover: header, the bindings list, an inline "add" composer,
/// and a footer. Sits on the dark "Night Console" backdrop.
struct RootView: View {
    @EnvironmentObject var model: BindingsModel
    @State private var adding = false

    var body: some View {
        VStack(spacing: 0) {
            header
            hairline

            if model.bindings.isEmpty && !adding {
                emptyState
            } else {
                bindingsList
            }

            if adding {
                AddBindingView(onDone: { withAnimation(.easeOut(duration: 0.18)) { adding = false } })
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                addButton
            }

            hairline
            footer
        }
        .frame(width: 384)
        .background(backdrop)
        .onAppear { model.errorMessage = nil }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.surfaceHi, Theme.surface],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Theme.strokeStrong, lineWidth: 1))
                    .frame(width: 34, height: 34)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Theme.accent)
                    .shadow(color: Theme.accent.opacity(0.6), radius: 5)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("BETTER").foregroundStyle(Theme.textPrimary)
                    Text("·").foregroundStyle(Theme.accent)
                    Text("TAB").foregroundStyle(Theme.textPrimary)
                }
                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                .tracking(2)

                Text("jump to any app with a keystroke")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Text("\(model.bindings.count)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.accent)
                + Text(model.bindings.count == 1 ? " shortcut" : " shortcuts")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textFaint)
        }
        .padding(.horizontal, 16)
        .padding(.top, 15)
        .padding(.bottom, 13)
    }

    // MARK: List

    private var bindingsList: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(model.bindings, id: \.self) { binding in
                    BindingRow(binding: binding, onRemove: {
                        withAnimation(.easeOut(duration: 0.16)) { model.remove(binding) }
                    })
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 320)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "keyboard")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.textFaint)
            Text("No shortcuts yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            Text("Bind a keystroke to launch or focus an app.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: Add

    private var addButton: some View {
        Button {
            model.errorMessage = nil
            withAnimation(.easeOut(duration: 0.18)) { adding = true }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text("New shortcut")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accentSoft)
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1)
                        .opacity(0.6))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Text("v1.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.textFaint)
            Spacer()
            Button {
                NSApp.terminate(nil)
            } label: {
                HStack(spacing: 5) {
                    Text("Quit")
                    Keycap(label: "⌘", lit: false, size: 18)
                    Keycap(label: "Q", lit: false, size: 18)
                }
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    // MARK: Chrome

    private var hairline: some View {
        Rectangle().fill(Theme.stroke).frame(height: 1)
    }

    private var backdrop: some View {
        ZStack {
            Theme.bg
            RadialGradient(
                colors: [Theme.accent.opacity(0.10), .clear],
                center: .topLeading, startRadius: 4, endRadius: 260
            )
            LinearGradient(
                colors: [Color.white.opacity(0.02), .clear],
                startPoint: .top, endPoint: .center
            )
        }
        .ignoresSafeArea()
    }
}
