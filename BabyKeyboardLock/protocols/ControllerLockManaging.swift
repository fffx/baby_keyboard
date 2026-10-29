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
    func unlockControllers()
}

/// Default implementation for production code using IOHIDManager to seize game controllers
class DefaultControllerLockManager: ControllerLockManaging {
    private var hidManager: IOHIDManager?
    private(set) var isLocked: Bool = false

    init() {}

    func lockControllers() {
        if isLocked { return }

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = manager

        let criteria: [[String: Any]] = [
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
        if !isLocked { return }

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

    func lockControllers() {
        lockControllersCalled = true
        isLocked = true
    }

    func unlockControllers() {
        unlockControllersCalled = true
        isLocked = false
    }

    func reset() {
        isLocked = false
        lockControllersCalled = false
        unlockControllersCalled = false
    }
}

