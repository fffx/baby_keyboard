//
//  MockSpeechSynthesizer.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import AVFoundation
@testable import BabyKeyboardLock

class MockSpeechSynthesizer: SpeechSynthesizing {
    var isSpeaking: Bool = false
    var spokenUtterances: [AVSpeechUtterance] = []
    var stopSpeakingCalled: Bool = false

    func speak(_ utterance: AVSpeechUtterance) {
        isSpeaking = true
        spokenUtterances.append(utterance)
    }

    @discardableResult
    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        isSpeaking = false
        stopSpeakingCalled = true
        return true
    }

    func reset() {
        isSpeaking = false
        spokenUtterances.removeAll()
        stopSpeakingCalled = false
    }
}

