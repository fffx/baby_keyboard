//
//  TestEnvironmentDetectionTests.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 28.10.2024.
//

import Testing
@testable import BabyKeyboardLock

struct TestEnvironmentDetectionTests {

    @Test func testMockManagerIsUsedAutomatically() async throws {
        // When creating EventHandler in tests without explicit manager,
        // it should automatically use MockEventTapManager
        let handler = EventHandler(isLocked: false)

        let manager = handler.testEventTapManager
        #expect(manager is MockEventTapManager, "Should automatically use MockEventTapManager in tests")
    }

    @Test func testAccessibilityPermissionGrantedInTests() async throws {
        // In test environment, accessibility should be automatically granted
        let handler = EventHandler(isLocked: false)

        #expect(handler.accessibilityPermissionGranted, "Accessibility should be automatically granted in tests")
    }
}

