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
    private let dateProvider: () -> Date

    init(throttleInterval: TimeInterval = 1.0, dateProvider: @escaping () -> Date = Date.init) {
        self.throttleInterval = throttleInterval
        self.dateProvider = dateProvider
    }

    func isThrottled() -> Bool {
        let now = dateProvider()

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

