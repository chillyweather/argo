import SwiftUI

@main
struct ArgoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @State private var windowConfigured = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onAppear {
                    configureWindowIfNeeded()
                }
                .onReceive(NotificationCenter.default.publisher(for: .argoDidExitFullScreen)) { _ in
                    appState.isFullScreenLayout = false
                }
        }
        .defaultSize(width: 600, height: 500)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("n")
            }
            CommandGroup(after: .sidebar) {
                Button("Toggle Full Screen") {
                    appState.isFullScreenLayout = WindowHelper.toggleFullScreen(
                        NSApp.mainWindow ?? NSApp.keyWindow,
                        alwaysOnTop: appState.alwaysOnTop
                    )
                }
                .keyboardShortcut("f", modifiers: .command)
            }
            CommandGroup(replacing: .textFormatting) {
                EmptyView()
            }
        }
    }

    private func configureWindowIfNeeded() {
        guard !windowConfigured else { return }
        guard let window = NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else { return }
        WindowHelper.startFloating(window)
        WindowHelper.configureWindow(window)
        if appState.alwaysOnTop {
            WindowHelper.setAlwaysOnTop(true, for: window)
        }
        WindowHelper.bringToFront(window)
        windowConfigured = true
    }
}

final class WindowCloseDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowCloseDelegate()

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(sender)
        return false
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        WindowHelper.restoreAfterFullScreen(notification.object as? NSWindow)
        NotificationCenter.default.post(name: .argoDidExitFullScreen, object: nil)
    }
}

extension Notification.Name {
    static let argoDidExitFullScreen = Notification.Name("argoDidExitFullScreen")
}
