import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var currentTheme: ThemeColors {
        ThemeColors.current(for: appState.theme, scheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            if appState.isPreviewingMarkdown {
                MarkdownPreviewView()
            } else {
                EditorView()
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(currentTheme.bg.opacity(appState.opacity))
        .environment(\.theme, currentTheme)
        .preferredColorScheme(appState.theme == .light ? .light : (appState.theme == .dark || appState.theme == .nord) ? .dark : nil)
        .onAppear {
            recoverDraftIfNeeded()
            if appState.mode == .todo {
                fetchTodo()
            }
            updateConfigStatus()
        }
        .onChange(of: appState.mode) { _, newMode in
            if newMode == .todo {
                fetchTodo()
            }
        }
        .onChange(of: appState.sbUrl) { _, _ in updateConfigStatus() }
        .onChange(of: appState.sbToken) { _, _ in updateConfigStatus() }
    }

    private func recoverDraftIfNeeded() {
        if let draft = appState.recoverDraft() {
            if appState.mode == .scratchpad {
                appState.draftContent = draft
            }
        }
    }

    private func fetchTodo() {
        guard !appState.sbUrl.isEmpty, !appState.sbToken.isEmpty else { return }
        Task {
            let client = SbClient(baseURL: appState.sbUrl, token: appState.sbToken)
            do {
                let content = try await client.fetchNote(path: "todo.md")
                appState.todoContent = content
            } catch {
                appState.todoContent = ""
            }
        }
    }

    private func updateConfigStatus() {
        if appState.sbUrl.isEmpty || appState.sbToken.isEmpty {
            appState.status = .configMissing
        } else if appState.status == .configMissing {
            appState.status = .ready
        }
    }
}
