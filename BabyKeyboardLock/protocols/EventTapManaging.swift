//
//  EventTapManaging.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 28.10.2024.
//

import Foundation
import CoreGraphics
import ApplicationServices

/// Protocol for managing event tap operations
/// Allows for dependency injection and testing without actual system event taps
protocol EventTapManaging {
    func createEventTap(
        tap: CGEventTapLocation,
        place: CGEventTapPlacement,
        options: CGEventTapOptions,
        eventsOfInterest: CGEventMask,
        callback: CGEventTapCallBack,
        userInfo: UnsafeMutableRawPointer?
    ) -> CFMachPort?

    func createRunLoopSource(_ machPort: CFMachPort?) -> CFRunLoopSource?
    func addSourceToRunLoop(_ source: CFRunLoopSource?)
    func enableTap(_ tap: CFMachPort?, enable: Bool)
    func isTapEnabled(_ tap: CFMachPort?) -> Bool
    func runLoop()
    func stopRunLoop()
}

/// Default implementation for production code
class DefaultEventTapManager: EventTapManaging {
    private var currentRunLoop: CFRunLoop?
    func createEventTap(
        tap: CGEventTapLocation,
        place: CGEventTapPlacement,
        options: CGEventTapOptions,
        eventsOfInterest: CGEventMask,
        callback: CGEventTapCallBack,
        userInfo: UnsafeMutableRawPointer?
    ) -> CFMachPort? {
        return CGEvent.tapCreate(
            tap: tap,
            place: place,
            options: options,
            eventsOfInterest: eventsOfInterest,
            callback: callback,
            userInfo: userInfo
        )
    }

    func createRunLoopSource(_ machPort: CFMachPort?) -> CFRunLoopSource? {
        guard let machPort = machPort else { return nil }
        return CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort, 0)
    }

    func addSourceToRunLoop(_ source: CFRunLoopSource?) {
        guard let source = source else { return }
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    }

    func enableTap(_ tap: CFMachPort?, enable: Bool) {
        guard let tap = tap else { return }
        CGEvent.tapEnable(tap: tap, enable: enable)
    }

    func isTapEnabled(_ tap: CFMachPort?) -> Bool {
        guard let tap = tap else { return false }
        return CGEvent.tapIsEnabled(tap: tap)
    }

    func runLoop() {
        currentRunLoop = CFRunLoopGetCurrent()
        CFRunLoopRun()
    }

    func stopRunLoop() {
        if let currentRunLoop {
            CFRunLoopStop(currentRunLoop)
        }
    }
}

/// Mock implementation for tests - does NOT call actual CGEvent APIs
class MockEventTapManager: EventTapManaging {
    var createEventTapCalled = false
    var enableTapCalled = false
    var isTapEnabledResult = true
    var runLoopCalled = false
    var stopRunLoopCalled = false
    var currentRunLoop: CFRunLoop?

    func createEventTap(
        tap: CGEventTapLocation,
        place: CGEventTapPlacement,
        options: CGEventTapOptions,
        eventsOfInterest: CGEventMask,
        callback: CGEventTapCallBack,
        userInfo: UnsafeMutableRawPointer?
    ) -> CFMachPort? {
        createEventTapCalled = true
        // Return nil in tests - we don't want to create any actual event taps
        // The EventHandler should handle nil gracefully or tests should not trigger this path
        return nil
    }

    func createRunLoopSource(_ machPort: CFMachPort?) -> CFRunLoopSource? {
        // Return nil in tests since we don't need actual run loop
        return nil
    }

    func addSourceToRunLoop(_ source: CFRunLoopSource?) {
        // No-op in tests
    }

    func enableTap(_ tap: CFMachPort?, enable: Bool) {
        enableTapCalled = true
    }

    func isTapEnabled(_ tap: CFMachPort?) -> Bool {
        return isTapEnabledResult
    }

    func runLoop() {
        runLoopCalled = true
        // Don't actually start a run loop in tests
    }

    func stopRunLoop() {
        stopRunLoopCalled = true
        // Don't actually stop a run loop in tests
    }
}

