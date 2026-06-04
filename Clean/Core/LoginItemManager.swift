import Foundation
import ServiceManagement

/// Registers/unregisters the app as a login item via `SMAppService`, so cleaning
/// can keep happening across reboots without the user re-launching it.
final class LoginItemManager {
    static let shared = LoginItemManager()
    private init() {}

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Brings the login-item registration in line with the desired state.
    /// Failures (e.g. running an unsigned build from Xcode's DerivedData) are
    /// ignored — they resolve once the app is built and run from /Applications.
    func sync(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("Clean: login item update failed: \(error.localizedDescription)")
        }
    }
}
