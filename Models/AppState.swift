import SwiftUI

@Observable
final class AppState {
    var status: AppStatus = .ready
    var errorMessage: String?
    var todoContent: String = ""
    var isSaving: Bool = false

    var sbUrl: String {
        didSet { persist() }
    }
    var sbToken: String {
        didSet { persist() }
    }
    var alwaysOnTop: Bool {
        didSet { persist() }
    }
    var opacity: Double {
        didSet { persist() }
    }
    var fontSize: Double {
        didSet { persist() }
    }
    var fontFamily: String {
        didSet { persist() }
    }
    var theme: AppTheme {
        didSet { persist() }
    }
    var mode: AppMode {
        didSet { persist() }
    }
    var draftContent: String {
        didSet { persist() }
    }

    private var statusResetTask: Task<Void, Never>?
    private var todoDebounceTask: Task<Void, Never>?

    init() {
        let defaults = UserDefaults.standard
        self.sbUrl = defaults.string(forKey: "sbUrl") ?? ""
        self.sbToken = defaults.string(forKey: "sbToken") ?? ""
        self.alwaysOnTop = defaults.object(forKey: "alwaysOnTop") as? Bool ?? false
        self.opacity = defaults.object(forKey: "opacity") as? Double ?? 1.0
        self.fontSize = defaults.object(forKey: "fontSize") as? Double ?? 14
        self.fontFamily = defaults.string(forKey: "fontFamily") ?? "System"
        self.theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .system
        self.mode = AppMode(rawValue: defaults.string(forKey: "mode") ?? "") ?? .scratchpad
        self.draftContent = defaults.string(forKey: "draftContent") ?? ""
    }

    func setStatus(_ status: AppStatus) {
        self.status = status
        self.errorMessage = nil
    }

    func setStatusWithReset(_ status: AppStatus, resetAfter interval: Duration = .seconds(2)) {
        self.status = status
        self.errorMessage = nil
        statusResetTask?.cancel()
        statusResetTask = Task {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            self.status = .ready
        }
    }

    func setError(_ message: String) {
        self.errorMessage = message
    }

    func clearError() {
        self.errorMessage = nil
    }

    func clearDraft() {
        draftContent = ""
    }

    func recoverDraft() -> String? {
        draftContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draftContent
    }

    func saveTodoDebounced(_ content: String) {
        todoContent = content
        todoDebounceTask?.cancel()
        guard !sbUrl.isEmpty, !sbToken.isEmpty else { return }
        todoDebounceTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            let client = SbClient(baseURL: sbUrl, token: sbToken)
            do {
                _ = try await client.saveNoteToPath(path: "todo.md", content: content)
                setStatusWithReset(.saved, resetAfter: .seconds(1.5))
            } catch {
                let errorDesc = error.localizedDescription
                status = AppStatus.parse(error: errorDesc)
                setError(errorDesc)
            }
        }
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(sbUrl, forKey: "sbUrl")
        defaults.set(sbToken, forKey: "sbToken")
        defaults.set(alwaysOnTop, forKey: "alwaysOnTop")
        defaults.set(opacity, forKey: "opacity")
        defaults.set(fontSize, forKey: "fontSize")
        defaults.set(fontFamily, forKey: "fontFamily")
        defaults.set(theme.rawValue, forKey: "theme")
        defaults.set(mode.rawValue, forKey: "mode")
        defaults.set(draftContent, forKey: "draftContent")
    }
}