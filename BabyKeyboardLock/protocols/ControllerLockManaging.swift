//
//  ControllerLockManaging.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 29.10.2024.
//

import Foundation
import IOKit
import IOKit.hid

/// Protocol for managing game controller locking via IOHIDManager
protocol ControllerLockManaging: AnyObject {
    var isLocked: Bool { get }
    func lockControllers()
    func lockControllers(matchingDevices: [InputDevice])
    func unlockControllers()
}

/// Default implementation for production code using IOHIDManager to seize game controllers
class DefaultControllerLockManager: ControllerLockManaging {
    private var hidManager: IOHIDManager?
    private(set) var isLocked: Bool = false

    init() {}

    func lockControllers() {
        lockControllers(matchingDevices: [])
    }

    func lockControllers(matchingDevices: [InputDevice]) {
        let blockedControllers = matchingDevices.filter { $0.type == .controller && $0.isBlocked }

        // If specific devices were provided and none of the controllers are blocked, unlock and exit
        if !matchingDevices.isEmpty && blockedControllers.isEmpty {
            unlockControllers()
            return
        }

        if isLocked {
            unlockControllers()
        }

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = manager

        var criteria: [[String: Any]] = []
        if !blockedControllers.isEmpty {
            for dev in blockedControllers {
                var dict: [String: Any] = [
                    kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop
                ]
                if let vid = dev.vendorID {
                    dict[kIOHIDVendorIDKey as String] = vid
                }
                if let pid = dev.productID {
                    dict[kIOHIDProductIDKey as String] = pid
                }
                if let loc = dev.locationID {
                    dict[kIOHIDLocationIDKey as String] = loc
                }
                criteria.append(dict)
            }
        } else {
            criteria = [
                [
                    kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
                    kIOHIDDeviceUsageKey as String: kHIDUsage_GD_GamePad
                ],
                [
                    kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
                    kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Joystick
                ],
                [
                    kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
                    kIOHIDDeviceUsageKey as String: kHIDUsage_GD_MultiAxisController
                ]
            ]
        }

        IOHIDManagerSetDeviceMatchingMultiple(manager, criteria as CFArray)

        let ret = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
        if ret == kIOReturnSuccess {
            isLocked = true
            debugLog("Game controllers locked successfully (seized)")
        } else {
            debugLog("Failed to seize game controllers: \(ret)")
        }
    }

    func unlockControllers() {
        if !isLocked && hidManager == nil { return }

        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            self.hidManager = nil
        }
        isLocked = false
        debugLog("Game controllers unlocked")
    }

    deinit {
        unlockControllers()
    }
}

/// Mock implementation for tests
class MockControllerLockManager: ControllerLockManaging {
    var isLocked: Bool = false
    var lockControllersCalled = false
    var unlockControllersCalled = false
    var lastLockedDevices: [InputDevice] = []

    func lockControllers() {
        lockControllers(matchingDevices: [])
    }

    func lockControllers(matchingDevices: [InputDevice]) {
        lockControllersCalled = true
        lastLockedDevices = matchingDevices
        let blocked = matchingDevices.filter { $0.type == .controller && $0.isBlocked }
        if !matchingDevices.isEmpty && blocked.isEmpty {
            isLocked = false
        } else {
            isLocked = true
        }
    }

    func unlockControllers() {
        unlockControllersCalled = true
        isLocked = false
    }

    func reset() {
        isLocked = false
        lockControllersCalled = false
        unlockControllersCalled = false
        lastLockedDevices = []
    }
}
