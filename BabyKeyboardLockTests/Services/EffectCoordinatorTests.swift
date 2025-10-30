//
//  EffectCoordinatorTests.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 28.10.2024.
//

import Testing
import CoreGraphics
@testable import BabyKeyboardLock

struct EffectCoordinatorTests {

    @MainActor
    @Test func testEffectCoordinatorInitialization() async throws {
        let coordinator = EffectCoordinator()

        #expect(coordinator.translationLanguage == .none, "Default translation language should be none")
    }

    @MainActor
    @Test func testNoneEffectReturnsKeyString() async throws {
        let mockSpeech = MockSpeechSynthesizer()
        let coordinator = EffectCoordinator(
            speechService: SpeechService(synthesizer: mockSpeech)
        )

        // Create a mock key event
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        let result = coordinator.handle(event: event, eventType: .keyUp, selectedLockEffect: .none)

        // With none effect, it should just return the key string without speaking
        #expect(!result.isEmpty, "Should return a key string")
        #expect(mockSpeech.spokenUtterances.isEmpty, "Should not speak with none effect")
    }

    @MainActor
    @Test func testConfettiEffectReturnsKeyString() async throws {
        let mockSpeech = MockSpeechSynthesizer()
        let coordinator = EffectCoordinator(
            speechService: SpeechService(synthesizer: mockSpeech)
        )

        // Create a mock key event for 'a' key (virtual key code 0)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        let result = coordinator.handle(event: event, eventType: .keyUp, selectedLockEffect: .confettiConnon)

        // With confetti effect, it should return key string but not speak
        #expect(!result.isEmpty, "Should return a key string")
        #expect(mockSpeech.spokenUtterances.isEmpty, "Confetti effect should not speak")
    }

    @MainActor
    @Test func testSpeakTheKeyEffect() async throws {
        let mockSpeech = MockSpeechSynthesizer()
        let coordinator = EffectCoordinator(
            speechService: SpeechService(synthesizer: mockSpeech)
        )

        // Create a mock key event for 'a' key (virtual key code 0)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        let result = coordinator.handle(event: event, eventType: .keyUp, selectedLockEffect: .speakTheKey)

        // Wait for async speech operation
        try await Task.sleep(for: .milliseconds(1000))

        #expect(!result.isEmpty, "Should return a key string")
        #expect(mockSpeech.spokenUtterances.count > 0, "Should speak the key")
    }

    @MainActor
    @Test func testSpeakAKeyWordEffect() async throws {
        let mockSpeech = MockSpeechSynthesizer()
        let coordinator = EffectCoordinator(
            speechService: SpeechService(synthesizer: mockSpeech)
        )

        // Create a mock key event for 'a' key (virtual key code 0)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        let result = coordinator.handle(event: event, eventType: .keyUp, selectedLockEffect: .speakAKeyWord)

        // Wait for async speech operation
        try await Task.sleep(for: .milliseconds(1000))

        #expect(!result.isEmpty, "Should return a random word")
        #expect(mockSpeech.spokenUtterances.count > 0, "Should speak a word")

        // The result should be a word that starts with 'a' (or the key pressed)
        #expect(result.count > 1, "Should return a word, not just a letter")
    }

    @MainActor
    @Test func testSpeakAKeyWordWithTranslation() async throws {
        let mockSpeech = MockSpeechSynthesizer()
        let coordinator = EffectCoordinator(
            speechService: SpeechService(synthesizer: mockSpeech)
        )
        coordinator.translationLanguage = .french

        // Create a mock key event for 'a' key
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        let result = coordinator.handle(event: event, eventType: .keyUp, selectedLockEffect: .speakAKeyWord)

        // Wait for async speech and translation
        try await Task.sleep(for: .milliseconds(1500))

        #expect(!result.isEmpty, "Should return a word")
        // Should speak twice: once for the word, once for translation
        #expect(mockSpeech.spokenUtterances.count >= 1, "Should speak at least the word")
    }

    @MainActor
    @Test func testGetStringForLetterKey() async throws {
        let coordinator = EffectCoordinator()

        // Create a key event for 'a' key (virtual key code 0)
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        let result = coordinator.getString(event: event, eventType: .keyUp)

        #expect(result != nil, "Should return a string for letter key")
        #expect(!result!.isEmpty, "String should not be empty")
    }

    @MainActor
    @Test func testTranslationLanguageSettable() async throws {
        let coordinator = EffectCoordinator()

        coordinator.translationLanguage = .spanish
        #expect(coordinator.translationLanguage == .spanish, "Translation language should be settable")

        coordinator.translationLanguage = .german
        #expect(coordinator.translationLanguage == .german, "Translation language should update")
    }

    @MainActor
    @Test func testAllLockEffects() async throws {
        let coordinator = EffectCoordinator()

        // Test that all lock effect cases are handled
        let allEffects: [LockEffect] = [.none, .confettiConnon, .speakTheKey, .speakAKeyWord]

        for effect in allEffects {
            guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
                Issue.record("Failed to create CGEvent")
                return
            }

            let result = coordinator.handle(event: event, eventType: .keyUp, selectedLockEffect: effect)
            #expect(!result.isEmpty, "Effect \(effect) should return a result")
        }
    }
}

