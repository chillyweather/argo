import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var windowConfigured = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureFirstWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                WindowHelper.bringToFront(window)
            }
        } else {
            WindowHelper.bringToFront(sender.keyWindow)
            WindowHelper.bringToFront(sender.mainWindow)
        }
        return true
    }

    private func configureFirstWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else { return }
            WindowHelper.startFloating(window)
            WindowHelper.configureWindow(window)
            WindowHelper.bringToFront(window)
            self.windowConfigured = true
        }
    }
}
