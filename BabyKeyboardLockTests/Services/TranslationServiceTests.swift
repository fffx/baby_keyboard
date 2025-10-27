//
//  TranslationServiceTests.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Testing
@testable import BabyKeyboardLock

struct TranslationServiceTests {

    @Test func testFrenchTranslation() async throws {
        let service = TranslationService()

        let translation = service.getTranslation(word: "apple", language: .french)
        #expect(translation == "pomme")
    }

    @Test func testRussianTranslation() async throws {
        let service = TranslationService()

        let translation = service.getTranslation(word: "cat", language: .russian)
        #expect(translation == "кот")
    }

    @Test func testGermanTranslation() async throws {
        let service = TranslationService()

        let translation = service.getTranslation(word: "dog", language: .german)
        #expect(translation == "Hund")
    }

    @Test func testSpanishTranslation() async throws {
        let service = TranslationService()

        let translation = service.getTranslation(word: "fish", language: .spanish)
        #expect(translation == "pez")
    }

    @Test func testItalianTranslation() async throws {
        let service = TranslationService()

        let translation = service.getTranslation(word: "moon", language: .italian)
        #expect(translation == "luna")
    }

    @Test func testJapaneseTranslation() async throws {
        let service = TranslationService()

        let translation = service.getTranslation(word: "sun", language: .japanese)
        #expect(translation == "たいよう")
    }

    @Test func testChineseTranslation() async throws {
        let service = TranslationService()

        let translation = service.getTranslation(word: "dog", language: .chinese)
        #expect(translation == "狗")
    }

    @Test func testTranslationWithNoneLanguage() async throws {
        let service = TranslationService()

        let translation = service.getTranslation(word: "apple", language: .none)
        #expect(translation == nil)
    }

    @Test func testTranslationCaseInsensitive() async throws {
        let service = TranslationService()

        let translation = service.getTranslation(word: "APPLE", language: .french)
        #expect(translation == "pomme")
    }

    @Test func testTranslationForUnknownWord() async throws {
        let service = TranslationService()

        let translation = service.getTranslation(word: "nonexistent", language: .french)
        #expect(translation == nil)
    }
}

