import Foundation
import ServiceManagement

/// Thin wrapper around `SMAppService.mainApp` (macOS 13+) for the Launch at Login toggle.
enum LoginItemManager {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Returns `false` when macOS rejects the change (e.g. the app bundle is not in a
    /// location the system accepts as a login item).
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status == .enabled { return true }
                try service.register()
            } else {
                try service.unregister()
            }
            return true
        } catch {
            NSLog("[D-Switch] Launch at Login \(enabled ? "enable" : "disable") failed: \(error.localizedDescription)")
            return false
        }
    }
}
