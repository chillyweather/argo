import AppKit

enum WindowHelper {
    private static var restoreAlwaysOnTopAfterFullScreen = false

    private static let floatingCollectionBehavior: NSWindow.CollectionBehavior = [
        .canJoinAllApplications,
        .fullScreenAuxiliary,
        .managed
    ]

    private static let pinnedCollectionBehavior: NSWindow.CollectionBehavior = [
        .canJoinAllSpaces,
        .canJoinAllApplications,
        .fullScreenAuxiliary,
        .managed
    ]

    static func setAlwaysOnTop(_ onTop: Bool, for window: NSWindow?) {
        guard let window else { return }
        window.level = onTop ? .screenSaver : .statusBar
        window.collectionBehavior = onTop ? pinnedCollectionBehavior : floatingCollectionBehavior
        bringToFront(window)
    }

    static func startFloating(_ window: NSWindow?) {
        guard let window else { return }
        window.level = .statusBar
        window.collectionBehavior = floatingCollectionBehavior
    }

    @discardableResult
    static func toggleFullScreen(_ window: NSWindow?, alwaysOnTop: Bool) -> Bool {
        guard let window else { return false }

        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
            return false
        }

        restoreAlwaysOnTopAfterFullScreen = alwaysOnTop
        prepareForFullScreen(window)
        window.toggleFullScreen(nil)
        return true
    }

    static func restoreAfterFullScreen(_ window: NSWindow?) {
        setAlwaysOnTop(restoreAlwaysOnTopAfterFullScreen, for: window)
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

    private static func prepareForFullScreen(_ window: NSWindow) {
        window.level = .normal
        window.collectionBehavior = [.fullScreenPrimary, .managed]
        window.styleMask.insert(.resizable)
        window.standardWindowButton(.zoomButton)?.isEnabled = true
    }
}
