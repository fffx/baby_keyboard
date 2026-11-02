//
//  ThrottleManagerTests.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Foundation
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

    @Test func testCallAfterIntervalNotThrottled() {
        var currentTime = Date()
        let manager = ThrottleManager(throttleInterval: 0.1, dateProvider: { currentTime })

        _ = manager.isThrottled() // First call
        currentTime = currentTime.addingTimeInterval(0.15) // Advance past interval
        let isThrottled = manager.isThrottled() // Second call after interval

        #expect(!isThrottled, "Call after interval should not be throttled")
    }

    @Test func testCustomThrottleInterval() {
        var currentTime = Date()
        let manager = ThrottleManager(throttleInterval: 0.2, dateProvider: { currentTime })

        _ = manager.isThrottled()
        currentTime = currentTime.addingTimeInterval(0.1) // 100ms elapsed (< 200ms)
        let isThrottled1 = manager.isThrottled()
        #expect(isThrottled1, "Should be throttled before interval")

        currentTime = currentTime.addingTimeInterval(0.15) // 250ms total elapsed (> 200ms)
        let isThrottled2 = manager.isThrottled()
        #expect(!isThrottled2, "Should not be throttled after interval")
    }
}

