import AppKit

enum WindowHelper {
    private static let floatingCollectionBehavior: NSWindow.CollectionBehavior = [
        .canJoinAllSpaces,
        .fullScreenAuxiliary,
        .managed
    ]

    static func setAlwaysOnTop(_ onTop: Bool, for window: NSWindow?) {
        guard let window else { return }
        window.level = onTop ? .statusBar : .floating
        window.collectionBehavior = floatingCollectionBehavior
    }

    static func startFloating(_ window: NSWindow?) {
        guard let window else { return }
        window.level = .floating
        window.collectionBehavior = floatingCollectionBehavior
    }

    static func configureWindow(_ window: NSWindow?) {
        guard let window else { return }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.hidesOnDeactivate = false
        window.collectionBehavior = floatingCollectionBehavior
        window.delegate = WindowCloseDelegate.shared
    }

    static func bringToFront(_ window: NSWindow?) {
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKey()
    }
}
