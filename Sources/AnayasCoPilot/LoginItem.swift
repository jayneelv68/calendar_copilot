import Foundation
import ServiceManagement

// Modern SMAppService-based login item. Fails gracefully if registration is not permitted
// (e.g. running unsigned outside /Applications, or sandbox/user denial).
public enum LoginItem {
    public static var isRegistered: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    @discardableResult
    public static func setEnabled(_ enabled: Bool) -> Bool {
        guard #available(macOS 13.0, *) else { return false }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            fputs("[login-item] \(enabled ? "register" : "unregister") failed: \(error)\n", stderr)
            return false
        }
    }
}
