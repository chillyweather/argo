import SwiftUI
import AppKit

struct EditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if appState.mode == .scratchpad {
                TextEditor(text: Binding(
                    get: { appState.draftContent },
                    set: { newValue in
                        appState.draftContent = newValue
                    }
                ))
            } else {
                TextEditor(text: Binding(
                    get: { appState.todoContent },
                    set: { newValue in
                        appState.saveTodoDebounced(newValue)
                    }
                ))
            }
        }
        .font(.system(size: 14, weight: .regular, design: .monospaced))
        .foregroundStyle(theme.text)
        .scrollContentBackground(.hidden)
        .padding(8)
        .disabled(appState.isSaving)
    }
}