//
//  InputDeviceManaging.swift
//  BabyKeyboardLock
//
//  Created by Antigravity on 29.10.2026.
//

import Foundation
import CoreGraphics

/// Protocol for managing input device discovery, monitoring, and blocking selection
protocol InputDeviceManaging: AnyObject {
    var devices: [InputDevice] { get }
    var isAnyKeyboardBlocked: Bool { get }
    var isAnyMouseBlocked: Bool { get }
    var isAnyControllerBlocked: Bool { get }

    func isDeviceBlocked(senderID: UInt64, eventType: CGEventType) -> Bool
    func setDeviceBlocked(id: String, isBlocked: Bool)
    func refreshDevices()
    func startMonitoring()
    func stopMonitoring()
}

/// Mock implementation for tests
class MockInputDeviceManager: InputDeviceManaging {
    var devices: [InputDevice] = []
    var isDeviceBlockedHandler: ((UInt64, CGEventType) -> Bool)?
    var setDeviceBlockedCalled = false
    var refreshDevicesCalled = false
    var startMonitoringCalled = false
    var stopMonitoringCalled = false

    var isAnyKeyboardBlocked: Bool {
        let keyboards = devices.filter { $0.type == .keyboard }
        return keyboards.isEmpty || keyboards.contains { $0.isBlocked }
    }

    var isAnyMouseBlocked: Bool {
        let mice = devices.filter { $0.type == .mouseOrTrackpad }
        return !mice.isEmpty && mice.contains { $0.isBlocked }
    }

    var isAnyControllerBlocked: Bool {
        let controllers = devices.filter { $0.type == .controller }
        return controllers.isEmpty || controllers.contains { $0.isBlocked }
    }

    func isDeviceBlocked(senderID: UInt64, eventType: CGEventType) -> Bool {
        if let handler = isDeviceBlockedHandler {
            return handler(senderID, eventType)
        }

        let isKeyboardEvent: Bool
        let isMouseEvent: Bool
        switch eventType {
        case .keyDown, .keyUp, .flagsChanged:
            isKeyboardEvent = true
            isMouseEvent = false
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
             .otherMouseDown, .otherMouseUp, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            isKeyboardEvent = false
            isMouseEvent = true
        default:
            isKeyboardEvent = false
            isMouseEvent = false
        }

        let targetType: InputDeviceType? = isKeyboardEvent ? .keyboard : (isMouseEvent ? .mouseOrTrackpad : nil)

        if let targetType = targetType {
            let matching = devices.filter { $0.type == targetType }
            if matching.isEmpty {
                return isKeyboardEvent ? isAnyKeyboardBlocked : isAnyMouseBlocked
            }
            if matching.count == 1 {
                return matching[0].isBlocked
            }
            if senderID != 0, let device = matching.first(where: { $0.registryEntryIDs.contains(senderID) }) {
                return device.isBlocked
            }
            return isKeyboardEvent ? isAnyKeyboardBlocked : isAnyMouseBlocked
        }

        return true
    }

    func setDeviceBlocked(id: String, isBlocked: Bool) {
        setDeviceBlockedCalled = true
        if let idx = devices.firstIndex(where: { $0.id == id }) {
            devices[idx].isBlocked = isBlocked
        }
    }

    func refreshDevices() {
        refreshDevicesCalled = true
    }

    func startMonitoring() {
        startMonitoringCalled = true
    }

    func stopMonitoring() {
        stopMonitoringCalled = true
    }

    func reset() {
        devices = []
        isDeviceBlockedHandler = nil
        setDeviceBlockedCalled = false
        refreshDevicesCalled = false
        startMonitoringCalled = false
        stopMonitoringCalled = false
    }
}
