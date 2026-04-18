import SwiftUI

struct EditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var theme
    @State private var selection: TextSelection?

    var body: some View {
        TextEditor(text: Binding(
            get: {
                appState.mode == .scratchpad ? appState.draftContent : appState.todoContent
            },
            set: { newValue in
                updateContent(newValue)
            }
        ), selection: $selection)
        .font(AppFont.font(family: appState.fontFamily, size: appState.fontSize))
        .foregroundStyle(theme.text)
        .scrollContentBackground(.hidden)
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .disabled(appState.isSaving)
    }

    private var currentContent: String {
        appState.mode == .scratchpad ? appState.draftContent : appState.todoContent
    }

    private func updateContent(_ newValue: String) {
        let oldValue = currentContent

        if let edit = MarkdownListContinuation.continuingListEdit(oldValue: oldValue, newValue: newValue) {
            setContent(edit.text)
            selection = TextSelection(insertionPoint: edit.insertionPoint)
        } else {
            setContent(newValue)
        }
    }

    private func setContent(_ content: String) {
        if appState.mode == .scratchpad {
            appState.draftContent = content
        } else {
            appState.todoContent = content
            appState.saveCurrentTodoDebounced()
        }
    }
}

private enum MarkdownListContinuation {
    struct Edit {
        let text: String
        let insertionPoint: String.Index
    }

    static func continuingListEdit(oldValue: String, newValue: String) -> Edit? {
        guard let insertion = singleInsertedNewline(oldValue: oldValue, newValue: newValue),
              let line = lineBeforeInsertion(in: oldValue, insertionIndex: insertion.oldIndex),
              let continuation = continuation(for: line.text) else {
            return nil
        }

        if continuation.shouldRemoveEmptyMarker {
            var updated = oldValue
            updated.replaceSubrange(line.range, with: continuation.indentation)
            let insertionPoint = updated.index(
                updated.startIndex,
                offsetBy: oldValue.distance(from: oldValue.startIndex, to: line.range.lowerBound)
                    + continuation.indentation.count
            )
            let text = updated.replacingCharacters(in: insertionPoint..<insertionPoint, with: "\n")
            return Edit(text: text, insertionPoint: text.index(after: insertionPoint))
        }

        var text = newValue
        text.insert(contentsOf: continuation.prefix, at: insertion.newIndexAfterNewline)
        let insertionPoint = text.index(
            insertion.newIndexAfterNewline,
            offsetBy: continuation.prefix.count
        )
        return Edit(text: text, insertionPoint: insertionPoint)
    }

    private struct Insertion {
        let oldIndex: String.Index
        let newIndexAfterNewline: String.Index
    }

    private struct SourceLine {
        let text: String
        let range: Range<String.Index>
    }

    private struct Continuation {
        let prefix: String
        let indentation: String
        let shouldRemoveEmptyMarker: Bool
    }

    private static func singleInsertedNewline(oldValue: String, newValue: String) -> Insertion? {
        guard newValue.count == oldValue.count + 1 else { return nil }

        var oldIndex = oldValue.startIndex
        var newIndex = newValue.startIndex

        while oldIndex < oldValue.endIndex,
              newIndex < newValue.endIndex,
              oldValue[oldIndex] == newValue[newIndex] {
            oldValue.formIndex(after: &oldIndex)
            newValue.formIndex(after: &newIndex)
        }

        guard newIndex < newValue.endIndex, newValue[newIndex] == "\n" else {
            return nil
        }

        let newIndexAfterNewline = newValue.index(after: newIndex)
        guard oldValue[oldIndex...] == newValue[newIndexAfterNewline...] else {
            return nil
        }

        return Insertion(oldIndex: oldIndex, newIndexAfterNewline: newIndexAfterNewline)
    }

    private static func lineBeforeInsertion(in text: String, insertionIndex: String.Index) -> SourceLine? {
        let prefix = text[..<insertionIndex]
        let lineStart = prefix.lastIndex(of: "\n").map { text.index(after: $0) } ?? text.startIndex
        return SourceLine(text: String(text[lineStart..<insertionIndex]), range: lineStart..<insertionIndex)
    }

    private static func continuation(for line: String) -> Continuation? {
        let indentation = String(line.prefix(while: { $0 == " " }))
        let trimmed = line.dropFirst(indentation.count)

        if let checklist = checklistContinuation(for: trimmed, indentation: indentation) {
            return checklist
        }

        if let bullet = bulletContinuation(for: trimmed, indentation: indentation) {
            return bullet
        }

        if let numbered = numberedContinuation(for: trimmed, indentation: indentation) {
            return numbered
        }

        return nil
    }

    private static func checklistContinuation(for line: Substring, indentation: String) -> Continuation? {
        let prefixes = ["- [ ] ", "* [ ] ", "+ [ ] ", "- [x] ", "* [x] ", "+ [x] ", "- [X] ", "* [X] ", "+ [X] "]
        guard let prefix = prefixes.first(where: { line.hasPrefix($0) }) else { return nil }

        let itemText = line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
        let marker = String(prefix.prefix(1))
        return Continuation(
            prefix: "\(indentation)\(marker) [ ] ",
            indentation: indentation,
            shouldRemoveEmptyMarker: itemText.isEmpty
        )
    }

    private static func bulletContinuation(for line: Substring, indentation: String) -> Continuation? {
        guard let marker = ["- ", "* ", "+ "].first(where: { line.hasPrefix($0) }) else {
            return nil
        }

        let itemText = line.dropFirst(marker.count).trimmingCharacters(in: .whitespaces)
        return Continuation(
            prefix: "\(indentation)\(marker)",
            indentation: indentation,
            shouldRemoveEmptyMarker: itemText.isEmpty
        )
    }

    private static func numberedContinuation(for line: Substring, indentation: String) -> Continuation? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }

        let numberText = line[..<dotIndex]
        guard let number = Int(numberText) else { return nil }

        let afterDot = line.index(after: dotIndex)
        guard afterDot < line.endIndex, line[afterDot] == " " else { return nil }

        let itemText = line[line.index(after: afterDot)...].trimmingCharacters(in: .whitespaces)
        return Continuation(
            prefix: "\(indentation)\(number + 1). ",
            indentation: indentation,
            shouldRemoveEmptyMarker: itemText.isEmpty
        )
    }
}
