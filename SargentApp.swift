import SwiftUI

@main
struct SargentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onAppear {
                    guard let window = NSApp.mainWindow ?? NSApp.windows.first else { return }
                    WindowHelper.startFloating(window)
                    WindowHelper.configureWindow(window)
                    if appState.alwaysOnTop {
                        WindowHelper.setAlwaysOnTop(true, for: window)
                    }
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
}

final class WindowCloseDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowCloseDelegate()

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(sender)
        return false
    }
}