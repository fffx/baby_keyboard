import Foundation
import ServiceManagement

class LaunchAtStartup {
    static let shared = LaunchAtStartup()
    private let launcherBundleId = "\(Bundle.main.bundleIdentifier!).LaunchHelper"
    
    private init() {}
    
    func setEnabled(_ enabled: Bool) {
        do {
            try SMAppService.mainApp.register()
        } catch {
            debugPrint("Failed to register app for launch at startup: \(error)")
        }
    }
    
    func isEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
} 