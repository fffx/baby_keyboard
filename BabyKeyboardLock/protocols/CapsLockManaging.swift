//
//  CapsLockManaging.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import Foundation
import IOKit
import IOKit.hid

protocol CapsLockManaging {
    func getCapsLockState() -> Bool
    func setCapsLockState(_ enabled: Bool)
}

class DefaultCapsLockManager: CapsLockManaging {
    func getCapsLockState() -> Bool {
        guard let matchingDict = IOServiceMatching(kIOHIDSystemClass) else { return false }
        let mainPort: mach_port_t
        if #available(macOS 12.0, *) {
            mainPort = kIOMainPortDefault
        } else {
            mainPort = kIOMasterPortDefault
        }
        let ioService = IOServiceGetMatchingService(mainPort, matchingDict)
        guard ioService != MACH_PORT_NULL else { return false }
        defer { IOObjectRelease(ioService) }

        var ioConnect: io_connect_t = 0
        let kr = IOServiceOpen(ioService, mach_task_self_, UInt32(kIOHIDParamConnectType), &ioConnect)
        guard kr == KERN_SUCCESS else { return false }
        defer { IOServiceClose(ioConnect) }

        var state = false
        let getRes = IOHIDGetModifierLockState(ioConnect, Int32(kIOHIDCapsLockState), &state)
        return getRes == KERN_SUCCESS && state
    }

    func setCapsLockState(_ enabled: Bool) {
        guard let matchingDict = IOServiceMatching(kIOHIDSystemClass) else { return }
        let mainPort: mach_port_t
        if #available(macOS 12.0, *) {
            mainPort = kIOMainPortDefault
        } else {
            mainPort = kIOMasterPortDefault
        }
        let ioService = IOServiceGetMatchingService(mainPort, matchingDict)
        guard ioService != MACH_PORT_NULL else { return }
        defer { IOObjectRelease(ioService) }

        var ioConnect: io_connect_t = 0
        let kr = IOServiceOpen(ioService, mach_task_self_, UInt32(kIOHIDParamConnectType), &ioConnect)
        guard kr == KERN_SUCCESS else { return }
        defer { IOServiceClose(ioConnect) }

        IOHIDSetModifierLockState(ioConnect, Int32(kIOHIDCapsLockState), enabled)
    }
}

class MockCapsLockManager: CapsLockManaging {
    var capsLockState: Bool = false
    var getCapsLockStateCalled = false
    var setCapsLockStateCalled = false

    func getCapsLockState() -> Bool {
        getCapsLockStateCalled = true
        return capsLockState
    }

    func setCapsLockState(_ enabled: Bool) {
        setCapsLockStateCalled = true
        capsLockState = enabled
    }

    func reset() {
        capsLockState = false
        getCapsLockStateCalled = false
        setCapsLockStateCalled = false
    }
}
