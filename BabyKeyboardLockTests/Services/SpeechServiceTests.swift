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

    @Test func testVoiceConsistencyAcrossMultipleCalls() async throws {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = SpeechService(synthesizer: mockSynthesizer)

        // Speak multiple times with the same language
        service.speak("apple")
        try await Task.sleep(for: .milliseconds(600))
        service.speak("banana")
        try await Task.sleep(for: .milliseconds(600))
        service.speak("cherry")
        try await Task.sleep(for: .milliseconds(600))

        // All utterances should use the same voice for the same language
        #expect(mockSynthesizer.spokenUtterances.count == 3)

        // Verify that all utterances have a voice set
        for utterance in mockSynthesizer.spokenUtterances {
            #expect(utterance.voice != nil)
        }

        // Verify that all utterances use the same voice (consistent voice selection)
        if mockSynthesizer.spokenUtterances.count > 1 {
            let firstVoice = mockSynthesizer.spokenUtterances[0].voice
            for i in 1..<mockSynthesizer.spokenUtterances.count {
                #expect(mockSynthesizer.spokenUtterances[i].voice?.identifier == firstVoice?.identifier)
            }
        }
    }

    @Test func testVoiceCachingForDifferentLanguages() async throws {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = SpeechService(synthesizer: mockSynthesizer)

        // Speak in English
        service.speak("hello", language: "en-US")
        try await Task.sleep(for: .milliseconds(600))

        // Speak in French
        service.speak("bonjour", language: "fr-FR")
        try await Task.sleep(for: .milliseconds(600))

        // Speak in English again - should use cached voice
        service.speak("goodbye", language: "en-US")
        try await Task.sleep(for: .milliseconds(600))

        #expect(mockSynthesizer.spokenUtterances.count == 3)

        // First and third should have same voice (both English)
        if mockSynthesizer.spokenUtterances.count >= 3 {
            let firstVoice = mockSynthesizer.spokenUtterances[0].voice
            let thirdVoice = mockSynthesizer.spokenUtterances[2].voice
            #expect(firstVoice?.identifier == thirdVoice?.identifier, "English voice should be consistent across calls")
        }
    }
}

