//
//  ThrottleManagerTests.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Testing
@testable import BabyKeyboardLock

struct ThrottleManagerTests {

    @Test func testInitialCallNotThrottled() async throws {
        let manager = ThrottleManager(throttleInterval: 1.0)

        let isThrottled = manager.isThrottled()

        #expect(!isThrottled, "First call should not be throttled")
    }

    @Test func testImmediateSecondCallIsThrottled() async throws {
        let manager = ThrottleManager(throttleInterval: 1.0)

        _ = manager.isThrottled() // First call
        let isThrottled = manager.isThrottled() // Immediate second call

        #expect(isThrottled, "Immediate second call should be throttled")
    }

    @Test func testCallAfterIntervalNotThrottled() async throws {
        let manager = ThrottleManager(throttleInterval: 0.1)

        _ = manager.isThrottled() // First call
        try await Task.sleep(for: .milliseconds(150)) // Wait longer than interval
        let isThrottled = manager.isThrottled() // Second call after interval

        #expect(!isThrottled, "Call after interval should not be throttled")
    }

    @Test func testCustomThrottleInterval() async throws {
        let manager = ThrottleManager(throttleInterval: 0.2)

        _ = manager.isThrottled()
        try await Task.sleep(for: .milliseconds(100))
        let isThrottled1 = manager.isThrottled()
        #expect(isThrottled1, "Should be throttled before interval")

        try await Task.sleep(for: .milliseconds(150))
        let isThrottled2 = manager.isThrottled()
        #expect(!isThrottled2, "Should not be throttled after interval")
    }
}

