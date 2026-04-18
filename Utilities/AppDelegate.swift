import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        } else {
            let keyWindow = sender.keyWindow
            let mainWindow = sender.mainWindow
            if keyWindow == nil && mainWindow == nil {
                for window in sender.windows {
                    window.makeKeyAndOrderFront(self)
                }
            } else {
                keyWindow?.makeKeyAndOrderFront(self)
                mainWindow?.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
}