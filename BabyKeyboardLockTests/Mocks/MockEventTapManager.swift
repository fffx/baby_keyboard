//
//  MockEventTapManager.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 28.10.2024.
//

@testable import BabyKeyboardLock
import Foundation
import CoreGraphics
import ApplicationServices

/// Test-specific mock that can be imported in test files
/// Note: MockEventTapManager is also available from BabyKeyboardLock module,
/// but this file provides a dedicated location for test-specific extensions if needed
extension MockEventTapManager {
    /// Reset all tracking flags for a fresh test
    func reset() {
        createEventTapCalled = false
        enableTapCalled = false
        isTapEnabledResult = true
        runLoopCalled = false
        stopRunLoopCalled = false
    }
}

