//
//  LockEffectTests.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 28.10.2024.
//

import Testing
import SwiftUI
@testable import BabyKeyboardLock

struct LockEffectTests {

    @Test func testAllLockEffectCases() async throws {
        let allCases = LockEffect.allCases

        #expect(allCases.count == 10, "Should have exactly 10 lock effect cases")
        #expect(allCases.contains(.basso), "Should contain basso effect")
        #expect(allCases.contains(.glass), "Should contain glass effect")
        #expect(allCases.contains(.ping), "Should contain ping effect")
        #expect(allCases.contains(.sosumi), "Should contain sosumi effect")
        #expect(allCases.contains(.submarine), "Should contain submarine effect")
        #expect(allCases.contains(.tink), "Should contain tink effect")
        #expect(allCases.contains(.none), "Should contain none effect")
        #expect(allCases.contains(.confettiConnon), "Should contain confetti cannon effect")
        #expect(allCases.contains(.speakTheKey), "Should contain speak the key effect")
        #expect(allCases.contains(.speakAKeyWord), "Should contain speak a key word effect")
    }

    @Test func testLockEffectRawValues() async throws {
        #expect(LockEffect.basso.rawValue == "LockEffect.basso")
        #expect(LockEffect.glass.rawValue == "LockEffect.glass")
        #expect(LockEffect.ping.rawValue == "LockEffect.ping")
        #expect(LockEffect.sosumi.rawValue == "LockEffect.sosumi")
        #expect(LockEffect.submarine.rawValue == "LockEffect.submarine")
        #expect(LockEffect.tink.rawValue == "LockEffect.tink")
        #expect(LockEffect.none.rawValue == "LockEffect.none")
        #expect(LockEffect.confettiConnon.rawValue == "LockEffect.confettiCannon")
        #expect(LockEffect.speakTheKey.rawValue == "LockEffect.speakTheKey")
        #expect(LockEffect.speakAKeyWord.rawValue == "LockEffect.speakAKeyWord")
    }

    @Test func testLockEffectSoundNames() async throws {
        #expect(LockEffect.basso.soundName == "Basso")
        #expect(LockEffect.glass.soundName == "Glass")
        #expect(LockEffect.ping.soundName == "Ping")
        #expect(LockEffect.sosumi.soundName == "Sosumi")
        #expect(LockEffect.submarine.soundName == "Submarine")
        #expect(LockEffect.tink.soundName == "Tink")
        #expect(LockEffect.none.soundName == nil)
        #expect(LockEffect.confettiConnon.soundName == nil)
        #expect(LockEffect.speakTheKey.soundName == nil)
        #expect(LockEffect.speakAKeyWord.soundName == nil)
    }

    @Test func testLockEffectIdentifiable() async throws {
        let effect = LockEffect.confettiConnon
        #expect(effect.id == .confettiConnon, "ID should match the case itself")
    }

    @Test func testLockEffectLocalizedString() async throws {
        // Test that localized strings are not empty
        for effect in LockEffect.allCases {
            let localized = effect.localizedString
            #expect(!localized.isEmpty, "Localized string should not be empty for \(effect)")
        }
    }

    @Test func testConfettiCannonEffect() async throws {
        let effect = LockEffect.confettiConnon

        #expect(effect == .confettiConnon, "Should be confetti cannon effect")
        #expect(effect.rawValue.contains("Cannon"), "Raw value should contain 'Cannon'")
    }
}

struct TranslationLanguageTests {

    @Test func testAllTranslationLanguageCases() async throws {
        let allCases = TranslationLanguage.allCases

        #expect(allCases.count == 8, "Should have exactly 8 translation language cases")
        #expect(allCases.contains(.none), "Should contain none")
        #expect(allCases.contains(.french), "Should contain french")
        #expect(allCases.contains(.russian), "Should contain russian")
        #expect(allCases.contains(.german), "Should contain german")
        #expect(allCases.contains(.spanish), "Should contain spanish")
        #expect(allCases.contains(.italian), "Should contain italian")
        #expect(allCases.contains(.japanese), "Should contain japanese")
        #expect(allCases.contains(.chinese), "Should contain chinese")
    }

    @Test func testTranslationLanguageCodes() async throws {
        #expect(TranslationLanguage.none.languageCode == "")
        #expect(TranslationLanguage.french.languageCode == "fr-FR")
        #expect(TranslationLanguage.russian.languageCode == "ru-RU")
        #expect(TranslationLanguage.german.languageCode == "de-DE")
        #expect(TranslationLanguage.spanish.languageCode == "es-ES")
        #expect(TranslationLanguage.italian.languageCode == "it-IT")
        #expect(TranslationLanguage.japanese.languageCode == "ja-JP")
        #expect(TranslationLanguage.chinese.languageCode == "zh-CN")
    }

    @Test func testTranslationLanguageRawValues() async throws {
        #expect(TranslationLanguage.french.rawValue == "TranslationLanguage.french")
        #expect(TranslationLanguage.spanish.rawValue == "TranslationLanguage.spanish")
        #expect(TranslationLanguage.chinese.rawValue == "TranslationLanguage.chinese")
    }

    @Test func testTranslationLanguageIdentifiable() async throws {
        let language = TranslationLanguage.japanese
        #expect(language.id == .japanese, "ID should match the case itself")
    }

    @Test func testTranslationLanguageLocalizedString() async throws {
        // Test that localized strings are not empty
        for language in TranslationLanguage.allCases {
            let localized = language.localizedString
            #expect(!localized.isEmpty, "Localized string should not be empty for \(language)")
        }
    }
}
