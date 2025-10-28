//
//  SpeechServiceTests.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Testing
@testable import BabyKeyboardLock

struct SpeechServiceTests {

    @Test func testSpeakCallsSynthesizer() async throws {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = SpeechService(synthesizer: mockSynthesizer)

        service.speak("hello")

        // Wait a bit for async operation on background queue
        try await Task.sleep(for: .milliseconds(500))

        #expect(mockSynthesizer.spokenUtterances.count > 0)
        #expect(mockSynthesizer.spokenUtterances.first?.speechString == "hello")
    }

    @Test func testStopSpeakingWhenAlreadySpeaking() async throws {
        let mockSynthesizer = MockSpeechSynthesizer()
        mockSynthesizer.isSpeaking = true
        let service = SpeechService(synthesizer: mockSynthesizer)

        service.speak("test")

        // Wait a bit for async operation on background queue
        try await Task.sleep(for: .milliseconds(500))

        #expect(mockSynthesizer.stopSpeakingCalled)
    }

    @Test func testStopSpeaking() async throws {
        let mockSynthesizer = MockSpeechSynthesizer()
        mockSynthesizer.isSpeaking = true
        let service = SpeechService(synthesizer: mockSynthesizer)

        service.stopSpeaking()

        #expect(mockSynthesizer.stopSpeakingCalled)
    }
}

