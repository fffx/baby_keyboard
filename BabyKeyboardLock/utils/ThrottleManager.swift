//
//  ThrottleManager.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Foundation

class ThrottleManager {
    private var lastEventTime: Date = Date()
    private let throttleInterval: TimeInterval

    init(throttleInterval: TimeInterval = 1.0) {
        self.throttleInterval = throttleInterval
    }

    func isThrottled() -> Bool {
        let now = Date()
        let timeSinceLastEvent = now.timeIntervalSince(lastEventTime)

        if timeSinceLastEvent >= throttleInterval {
            lastEventTime = now
            return false
        }
        debugLog("Throttled >>>>> timeSinceLastEvent: \(timeSinceLastEvent)")
        return true
    }
}

