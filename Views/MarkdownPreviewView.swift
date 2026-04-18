import SwiftUI

struct MarkdownPreviewView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var theme

    private var content: String {
        appState.mode == .scratchpad ? appState.draftContent : appState.todoContent
    }

    private var blocks: [MarkdownBlock] {
        MarkdownBlock.parse(content)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(blocks) { block in
                    blockView(block)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block.kind {
        case .heading(let level, let text):
            Text(text)
                .font(headingFont(for: level))
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, level == 1 ? 4 : 2)
        case .paragraph(let text):
            Text(text)
                .font(AppFont.font(family: appState.fontFamily, size: appState.fontSize))
                .foregroundStyle(theme.text)
                .textSelection(.enabled)
        case .bullet(let text, let depth):
            listRow(marker: "•", text: text, depth: depth)
        case .numbered(let number, let text, let depth):
            listRow(marker: "\(number).", text: text, depth: depth)
        case .checklist(let isChecked, let text, let depth):
            Button {
                toggleChecklist(at: block.lineIndex)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .foregroundStyle(isChecked ? theme.accent : theme.textMuted)
                    Text(text)
                        .font(AppFont.font(family: appState.fontFamily, size: appState.fontSize))
                        .foregroundStyle(isChecked ? theme.textMuted : theme.text)
                        .strikethrough(isChecked, color: theme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .padding(.leading, CGFloat(depth) * 18)
        case .empty:
            Spacer()
                .frame(height: 4)
        }
    }

    private func listRow(marker: String, text: String, depth: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(marker)
                .font(AppFont.font(family: appState.fontFamily, size: appState.fontSize))
                .foregroundStyle(theme.textMuted)
                .frame(width: 24, alignment: .trailing)
            Text(text)
                .font(AppFont.font(family: appState.fontFamily, size: appState.fontSize))
                .foregroundStyle(theme.text)
                .textSelection(.enabled)
        }
        .padding(.leading, CGFloat(depth) * 18)
    }

    private func headingFont(for level: Int) -> Font {
        let size = max(appState.fontSize + Double(7 - min(level, 6)) * 2, appState.fontSize)
        return AppFont.font(family: appState.fontFamily, size: size).weight(.semibold)
    }

    private func toggleChecklist(at lineIndex: Int) {
        var lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.indices.contains(lineIndex) else { return }
        guard let toggledLine = MarkdownBlock.toggledChecklistLine(lines[lineIndex]) else { return }

        lines[lineIndex] = toggledLine
        let updatedContent = lines.joined(separator: "\n")

        if appState.mode == .scratchpad {
            appState.draftContent = updatedContent
        } else {
            appState.saveTodoDebounced(updatedContent)
        }
    }
}

private struct MarkdownBlock: Identifiable {
    let id: Int
    let lineIndex: Int
    let kind: Kind

    enum Kind {
        case heading(level: Int, text: String)
        case paragraph(String)
        case bullet(text: String, depth: Int)
        case numbered(number: Int, text: String, depth: Int)
        case checklist(isChecked: Bool, text: String, depth: Int)
        case empty
    }

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        markdown
            .split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated()
            .map { index, line in
                MarkdownBlock(id: index, lineIndex: index, kind: parseLine(String(line)))
            }
    }

    private static func parseLine(_ line: String) -> Kind {
        guard !line.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .empty
        }

        let depth = indentationDepth(for: line)
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if let heading = parseHeading(trimmed) {
            return .heading(level: heading.level, text: heading.text)
        }

        if let checklist = parseChecklist(trimmed) {
            return .checklist(isChecked: checklist.isChecked, text: checklist.text, depth: depth)
        }

        if let bullet = parseBullet(trimmed) {
            return .bullet(text: bullet, depth: depth)
        }

        if let numbered = parseNumbered(trimmed) {
            return .numbered(number: numbered.number, text: numbered.text, depth: depth)
        }

        return .paragraph(trimmed)
    }

    private static func indentationDepth(for line: String) -> Int {
        let spaces = line.prefix(while: { $0 == " " }).count
        return spaces / 2
    }

    private static func parseHeading(_ line: String) -> (level: Int, text: String)? {
        let markers = line.prefix(while: { $0 == "#" })
        guard (1...6).contains(markers.count),
              line.dropFirst(markers.count).first == " " else {
            return nil
        }
        let text = line.dropFirst(markers.count + 1).trimmingCharacters(in: .whitespaces)
        return (markers.count, text)
    }

    private static func parseChecklist(_ line: String) -> (isChecked: Bool, text: String)? {
        guard let match = checklistPrefixes.first(where: { line.hasPrefix($0.prefix) }) else {
            return nil
        }

        return (match.isChecked, String(line.dropFirst(match.prefix.count)))
    }

    static func toggledChecklistLine(_ line: String) -> String? {
        let indentation = String(line.prefix(while: { $0 == " " }))
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        guard let match = checklistPrefixes.first(where: { trimmed.hasPrefix($0.prefix) }) else {
            return nil
        }

        let text = trimmed.dropFirst(match.prefix.count)
        let marker = String(match.prefix.prefix(1))
        let checkbox = match.isChecked ? "[ ]" : "[x]"
        return "\(indentation)\(marker) \(checkbox) \(text)"
    }

    private static let checklistPrefixes: [(prefix: String, isChecked: Bool)] = [
        ("- [ ] ", false),
        ("* [ ] ", false),
        ("+ [ ] ", false),
        ("- [x] ", true),
        ("* [x] ", true),
        ("+ [x] ", true),
        ("- [X] ", true),
        ("* [X] ", true),
        ("+ [X] ", true)
    ]

    private static func parseBullet(_ line: String) -> String? {
        for prefix in ["- ", "* ", "+ "] where line.hasPrefix(prefix) {
            return String(line.dropFirst(prefix.count))
        }
        return nil
    }

    private static func parseNumbered(_ line: String) -> (number: Int, text: String)? {
        guard let dotIndex = line.firstIndex(of: ".") else {
            return nil
        }

        let numberText = line[..<dotIndex]
        guard let number = Int(numberText) else {
            return nil
        }

        let textStart = line.index(after: dotIndex)
        guard textStart < line.endIndex, line[textStart] == " " else {
            return nil
        }

        return (number, String(line[line.index(after: textStart)...]))
    }
}
