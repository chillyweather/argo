import SwiftUI

struct EditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var theme

    var body: some View {
        TextEditor(text: Binding(
            get: {
                appState.mode == .scratchpad ? appState.draftContent : appState.todoContent
            },
            set: { newValue in
                if appState.mode == .scratchpad {
                    appState.draftContent = newValue
                } else {
                    appState.saveTodoDebounced(newValue)
                }
            }
        ))
        .font(AppFont.font(family: appState.fontFamily, size: appState.fontSize))
        .foregroundStyle(theme.text)
        .scrollContentBackground(.hidden)
        .padding(8)
        .disabled(appState.isSaving)
    }
}
