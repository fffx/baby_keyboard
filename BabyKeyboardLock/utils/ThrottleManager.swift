//
//  ThrottleManager.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Foundation

class ThrottleManager {
    private var lastEventTime: Date?
    private let throttleInterval: TimeInterval

    init(throttleInterval: TimeInterval = 1.0) {
        self.throttleInterval = throttleInterval
    }

    func isThrottled() -> Bool {
        let now = Date()

        guard let lastEventTime = lastEventTime else {
            // First call - not throttled
            self.lastEventTime = now
            return false
        }

        let timeSinceLastEvent = now.timeIntervalSince(lastEventTime)

        if timeSinceLastEvent >= throttleInterval {
            self.lastEventTime = now
            return false
        }
        debugLog("Throttled >>>>> timeSinceLastEvent: \(timeSinceLastEvent)")
        return true
    }
}

