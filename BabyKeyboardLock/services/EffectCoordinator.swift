//
//  EffectCoordinator.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Cocoa
import Carbon
import CoreGraphics
import Sauce

class EffectCoordinator {
    private let wordService: WordService
    private let translationService: TranslationService
    private let speechService: SpeechService

    var translationLanguage: TranslationLanguage = .none

    init(wordService: WordService = WordService(),
         translationService: TranslationService = TranslationService(),
         speechService: SpeechService = SpeechService()) {
        self.wordService = wordService
        self.translationService = translationService
        self.speechService = speechService
    }

    func handle(event: CGEvent, eventType: CGEventType, selectedLockEffect: LockEffect) -> String {
        debugLog("speaking handle ------- \(selectedLockEffect)")
        guard let str = getString(event: event, eventType: eventType) else { return "" }
        debugLog("get key name ------- \(str)")

        switch selectedLockEffect {
        case .speakTheKey:
            speechService.speak(str)
        case .speakAKeyWord:
            let randomWord = wordService.getRandomWord(forKey: str)
            speechService.speak(randomWord)

            // If translation is enabled, speak the translation after a short delay
            if translationLanguage != .none {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    if let translatedWord = self.translationService.getTranslation(word: randomWord, language: self.translationLanguage) {
                        self.speechService.speak(translatedWord, language: self.translationLanguage.languageCode)
                    }
                }
            }
            return randomWord
        default:
            break
        }

        return str
    }

    func getString(event: CGEvent, eventType: CGEventType) -> String? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if KeyCode.allCases.contains(where: { $0.rawValue == keyCode }) {
            return String(describing: KeyCode(rawValue: CGKeyCode(keyCode))!)
        }

        return Sauce.shared.character(
            for: Int(event.getIntegerValueField(.keyboardEventKeycode)),
            cocoaModifiers: event.flags.toNSEventModifierFlags
        )
    }
}

