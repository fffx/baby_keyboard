//
//  TypingGameState.swift
//  BabyKeyboardLock
//
//  Created by Claude on 24.10.2025.
//
import Foundation
import Combine

enum TypingValidationResult {
    case correct           // Letter matches
    case incorrect         // Letter doesn't match
    case wordComplete      // Word fully typed
}

class TypingGameState: ObservableObject {
    static let shared = TypingGameState()

    @Published var currentWord: String = ""
    @Published var currentWordTranslation: String = ""
    @Published var typedSoFar: String = ""
    @Published var resetOnError: Bool = false
    @Published var isWordComplete: Bool = false

    private let customWordSetsManager = CustomWordSetsManager.shared
    private let randomWordList = RandomWordList.shared

    private init() {
        // Load reset on error setting from UserDefaults
        self.resetOnError = UserDefaults.standard.bool(forKey: "typingGameResetOnError")
    }

    func setResetOnError(_ value: Bool) {
        resetOnError = value
        UserDefaults.standard.set(value, forKey: "typingGameResetOnError")
    }

    // Validate a key press against the current word
    func validateKeyPress(_ key: String) -> TypingValidationResult {
        guard !currentWord.isEmpty else {
            return .incorrect
        }

        let nextExpectedIndex = typedSoFar.count

        // Check if we've already completed the word
        if nextExpectedIndex >= currentWord.count {
            return .wordComplete
        }

        // Get the next expected character
        let currentWordLower = currentWord.lowercased()
        let keyLower = key.lowercased()
        let expectedChar = String(currentWordLower[currentWordLower.index(currentWordLower.startIndex, offsetBy: nextExpectedIndex)])

        if keyLower == expectedChar {
            // Correct letter - add to typed progress
            typedSoFar += String(currentWord[currentWord.index(currentWord.startIndex, offsetBy: nextExpectedIndex)])

            // Check if word is now complete
            if typedSoFar.count == currentWord.count {
                isWordComplete = true
                return .wordComplete
            }

            return .correct
        } else {
            // Incorrect letter
            if resetOnError {
                // Reset progress
                typedSoFar = ""
            }
            return .incorrect
        }
    }

    // Select a new word from the available word sets
    func selectNewWord(wordSetType: WordSetType, translationLanguage: TranslationLanguage) {
        // Reset state
        typedSoFar = ""
        isWordComplete = false
        currentWordTranslation = ""

        if wordSetType == .mainWords {
            // Use custom word sets
            if let wordPairs = customWordSetsManager.currentWordSet?.words, !wordPairs.isEmpty {
                let randomPair = wordPairs.randomElement()!
                currentWord = randomPair.english
                currentWordTranslation = randomPair.translation
            } else {
                // Fallback to simple words
                selectFromSimpleWords(translationLanguage: translationLanguage)
            }
        } else if wordSetType == .randomShortWords {
            // Use random word list
            if let randomWord = randomWordList.getRandomWord() {
                currentWord = randomWord.english
                currentWordTranslation = randomWord.translation
            } else {
                // Fallback to simple words
                selectFromSimpleWords(translationLanguage: translationLanguage)
            }
        } else {
            // Fallback
            selectFromSimpleWords(translationLanguage: translationLanguage)
        }

        debugPrint("TypingGame: Selected new word '\(currentWord)'")
    }

    private func selectFromSimpleWords(translationLanguage: TranslationLanguage) {
        // Fallback to built-in simple words
        let simpleWords = ["cat", "dog", "sun", "moon", "star", "ball", "cup", "hat", "pig", "cow"]
        currentWord = simpleWords.randomElement() ?? "cat"

        // Try to get translation
        let eventEffectHandler = EventEffectHandler()
        if let translation = eventEffectHandler.getTranslation(word: currentWord, language: translationLanguage) {
            currentWordTranslation = translation
        }
    }

    // Reset the current typing progress
    func reset() {
        typedSoFar = ""
        isWordComplete = false
    }

    // Get the remaining letters to type
    func getRemainingLetters() -> String {
        guard !currentWord.isEmpty else { return "" }
        let remaining = String(currentWord.dropFirst(typedSoFar.count))
        return remaining
    }
}
