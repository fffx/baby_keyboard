//
//  WordServiceTests.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Testing
@testable import BabyKeyboardLock

struct WordServiceTests {

    @Test func testSimpleWordsMapContainsAllLetters() async throws {
        let service = WordService()
        let alphabet = "abcdefghijklmnopqrstuvwxyz"

        for letter in alphabet {
            let key = String(letter)
            #expect(service.simpleWordsMap[key] != nil, "Missing words for letter: \(key)")
            #expect(!service.simpleWordsMap[key]!.isEmpty, "Empty word list for letter: \(key)")
        }
    }

    @Test func testGetRandomWordReturnsValidWord() async throws {
        let service = WordService()

        // Test with valid letter
        let word = service.getRandomWord(forKey: "a")
        let expectedWords = ["apple", "ant", "air", "arm", "axe", "all", "ask", "and", "add"]
        #expect(expectedWords.contains(word))
    }

    @Test func testGetRandomWordWithInvalidKey() async throws {
        let service = WordService()

        // Test with invalid key - should return the key itself
        let result = service.getRandomWord(forKey: "1")
        #expect(result == "1")
    }

    @Test func testGetRandomWordCaseInsensitive() async throws {
        let service = WordService()

        // Test uppercase input
        let word = service.getRandomWord(forKey: "A")
        let expectedWords = ["apple", "ant", "air", "arm", "axe", "all", "ask", "and", "add"]
        #expect(expectedWords.contains(word))
    }

    @Test func testAllLettersHaveAtLeastThreeWords() async throws {
        let service = WordService()

        for (key, words) in service.simpleWordsMap {
            #expect(words.count >= 3, "Letter '\(key)' has less than 3 words: \(words.count)")
        }
    }
}

