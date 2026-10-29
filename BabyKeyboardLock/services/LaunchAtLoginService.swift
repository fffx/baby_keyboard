//
//  LaunchAtLoginService.swift
//  BabyKeyboardLock
//

import Foundation
import ServiceManagement

enum LaunchAtLoginService {
    static var isSupported: Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }

    static var isEnabled: Bool {
        guard #available(macOS 13.0, *) else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        guard #available(macOS 13.0, *) else { return false }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return isEnabled
        } catch {
            debugLog("Unable to update launch-at-login: \(error.localizedDescription)")
            return false
        }
    }
}
