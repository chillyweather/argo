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
        }
        .defaultSize(width: 600, height: 500)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("n")
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
}
