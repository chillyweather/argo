import SwiftUI

struct TopBar: View {
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Button {
                appState.mode = appState.mode == .scratchpad ? .todo : .scratchpad
            } label: {
                Image(systemName: appState.mode == .todo ? "checklist" : "note.text")
                    .foregroundStyle(appState.mode == .todo ? theme.accent : theme.textMuted)
            }
            .buttonStyle(.plain)
            .help(appState.mode == .scratchpad ? "Switch to Todo (⌘D)" : "Switch to Scratchpad (⌘D)")
            .keyboardShortcut("d", modifiers: .command)

            if !appState.sbUrl.isEmpty {
                Button {
                    if let url = URL(string: appState.sbUrl) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(theme.textMuted)
                }
                .buttonStyle(.plain)
                .help("Open SilverBullet")
            }

            Spacer()

            if appState.mode == .scratchpad {
                Button {
                    Task { await saveScratchpad() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Save")
                            .font(.caption)
                    }
                    .foregroundStyle(theme.text)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: .command)
                .help("Save (⌘↵)")
                .disabled(appState.isSaving)
            } else {
                Text("todo.md")
                    .font(.caption)
                    .foregroundStyle(theme.textMuted)
            }

            if appState.status != .ready {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
            }

            Text(appState.status.text)
                .font(.caption2)
                .foregroundStyle(theme.textMuted)
                .lineLimit(1)

            Button {
                appState.alwaysOnTop.toggle()
                if let window = NSApp.mainWindow {
                    WindowHelper.setAlwaysOnTop(appState.alwaysOnTop, for: window)
                }
            } label: {
                Image(systemName: appState.alwaysOnTop ? "pin.fill" : "pin")
                    .foregroundStyle(appState.alwaysOnTop ? theme.accent : theme.textMuted)
            }
            .buttonStyle(.plain)
            .help("Pin to top")

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(theme.textMuted)
            }
            .buttonStyle(.plain)
            .help("Settings")
            .keyboardShortcut(",", modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.bg.opacity(appState.opacity))
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    @State private var showingSettings = false

    private var statusColor: Color {
        switch appState.status {
        case .saving: theme.accent
        case .saved: theme.success
        case .offline, .authError, .serverError, .configMissing: theme.error
        default: theme.textMuted
        }
    }

    private func saveScratchpad() async {
        let content = appState.draftContent
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        guard !appState.sbUrl.isEmpty else {
            appState.status = .configMissing
            appState.setError("SilverBullet URL is not configured")
            showingSettings = true
            return
        }
        guard !appState.sbToken.isEmpty else {
            appState.status = .configMissing
            appState.setError("SilverBullet token is not configured")
            showingSettings = true
            return
        }

        appState.isSaving = true
        appState.status = .saving

        let client = SbClient(baseURL: appState.sbUrl, token: appState.sbToken)
        do {
            _ = try await client.saveNote(content: content)
            appState.clearDraft()
            appState.setStatusWithReset(.saved)
        } catch {
            let errorDesc = error.localizedDescription
            appState.status = AppStatus.parse(error: errorDesc)
            appState.setError(errorDesc)
        }
        appState.isSaving = false
    }
}
