//
//  SpeechServiceTests.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Testing
@testable import BabyKeyboardLock

struct SpeechServiceTests {

    @Test func testSpeakCallsSynthesizer() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = SpeechService(synthesizer: mockSynthesizer, queue: nil)

        service.speak("hello")

        #expect(mockSynthesizer.spokenUtterances.count > 0)
        #expect(mockSynthesizer.spokenUtterances.first?.speechString == "hello")
    }

    @Test func testStopSpeakingWhenAlreadySpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        mockSynthesizer.isSpeaking = true
        let service = SpeechService(synthesizer: mockSynthesizer, queue: nil)

        service.speak("test")

        #expect(mockSynthesizer.stopSpeakingCalled)
    }

    @Test func testStopSpeaking() {
        let mockSynthesizer = MockSpeechSynthesizer()
        mockSynthesizer.isSpeaking = true
        let service = SpeechService(synthesizer: mockSynthesizer, queue: nil)

        service.stopSpeaking()

        #expect(mockSynthesizer.stopSpeakingCalled)
    }

    @Test func testVoiceConsistencyAcrossMultipleCalls() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = SpeechService(synthesizer: mockSynthesizer, queue: nil)

        // Speak multiple times with the same language
        service.speak("apple")
        service.speak("banana")
        service.speak("cherry")

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

    @Test func testVoiceCachingForDifferentLanguages() {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = SpeechService(synthesizer: mockSynthesizer, queue: nil)

        // Speak in English
        service.speak("hello", language: "en-US")

        // Speak in French
        service.speak("bonjour", language: "fr-FR")

        // Speak in English again - should use cached voice
        service.speak("goodbye", language: "en-US")

        #expect(mockSynthesizer.spokenUtterances.count == 3)

        // First and third should have same voice (both English)
        if mockSynthesizer.spokenUtterances.count >= 3 {
            let firstVoice = mockSynthesizer.spokenUtterances[0].voice
            let thirdVoice = mockSynthesizer.spokenUtterances[2].voice
            #expect(firstVoice?.identifier == thirdVoice?.identifier, "English voice should be consistent across calls")
        }
    }

    @Test func testSpeakDispatchesAsynchronouslyByDefault() async throws {
        let mockSynthesizer = MockSpeechSynthesizer()
        let service = SpeechService(synthesizer: mockSynthesizer)

        let spoken = await withCheckedContinuation { continuation in
            var resumed = false
            mockSynthesizer.onSpeak = { _ in
                if !resumed {
                    resumed = true
                    continuation.resume(returning: true)
                }
            }
            service.speak("async test")
            Task {
                try? await Task.sleep(for: .seconds(3))
                if !resumed {
                    resumed = true
                    continuation.resume(returning: false)
                }
            }
        }

        #expect(spoken, "Speech should be performed on the background queue")
        #expect(mockSynthesizer.spokenUtterances.first?.speechString == "async test")
    }
}

