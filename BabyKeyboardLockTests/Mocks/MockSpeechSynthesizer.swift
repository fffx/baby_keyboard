//
//  MockSpeechSynthesizer.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import AVFoundation
@testable import BabyKeyboardLock

class MockSpeechSynthesizer: SpeechSynthesizing, @unchecked Sendable {
    private let lock = NSLock()
    private var _isSpeaking: Bool = false
    private var _spokenUtterances: [AVSpeechUtterance] = []
    private var _stopSpeakingCalled: Bool = false

    var onSpeak: ((AVSpeechUtterance) -> Void)?
    var onStopSpeaking: (() -> Void)?

    var isSpeaking: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _isSpeaking
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _isSpeaking = newValue
        }
    }

    var spokenUtterances: [AVSpeechUtterance] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _spokenUtterances
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _spokenUtterances = newValue
        }
    }

    var stopSpeakingCalled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _stopSpeakingCalled
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _stopSpeakingCalled = newValue
        }
    }

    func speak(_ utterance: AVSpeechUtterance) {
        lock.lock()
        _isSpeaking = true
        _spokenUtterances.append(utterance)
        let callback = onSpeak
        lock.unlock()
        callback?(utterance)
    }

    @discardableResult
    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        lock.lock()
        _isSpeaking = false
        _stopSpeakingCalled = true
        let callback = onStopSpeaking
        lock.unlock()
        callback?()
        return true
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _isSpeaking = false
        _spokenUtterances.removeAll()
        _stopSpeakingCalled = false
        onSpeak = nil
        onStopSpeaking = nil
    }
}

