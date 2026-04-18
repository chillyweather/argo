import AppKit

enum WindowHelper {
    static func setAlwaysOnTop(_ onTop: Bool, for window: NSWindow?) {
        guard let window else { return }
        let level: NSWindow.Level = onTop ? .init(rawValue: 8) : .normal
        window.level = level

        var behavior: NSWindow.CollectionBehavior = .managed
        if onTop {
            behavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .managed]
        }
        window.collectionBehavior = behavior
    }

    static func startFloating(_ window: NSWindow?) {
        guard let window else { return }
        window.level = NSWindow.Level(rawValue: 8)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .managed]
    }

    static func configureWindow(_ window: NSWindow?) {
        guard let window else { return }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.delegate = WindowCloseDelegate.shared
    }
}