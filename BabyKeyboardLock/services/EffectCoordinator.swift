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
    // Lazy initialize services to reduce initial memory footprint
    private lazy var wordService: WordService = WordService()
    private lazy var translationService: TranslationService = TranslationService()
    private lazy var speechService: SpeechService = SpeechService()
    private var translationWorkItem: DispatchWorkItem?

    var translationLanguage: TranslationLanguage = .none

    init(wordService: WordService? = nil,
         translationService: TranslationService? = nil,
         speechService: SpeechService? = nil) {
        // Allow dependency injection for testing while defaulting to lazy initialization
        if let wordService = wordService {
            self.wordService = wordService
        }
        if let translationService = translationService {
            self.translationService = translationService
        }
        if let speechService = speechService {
            self.speechService = speechService
        }
    }

    deinit {
        // Cancel any pending translation tasks to prevent memory leaks
        translationWorkItem?.cancel()
        translationWorkItem = nil
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
                // Cancel any existing translation work to prevent memory accumulation
                translationWorkItem?.cancel()

                // Create a new work item with weak self to prevent retain cycles
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    if let translatedWord = self.translationService.getTranslation(word: randomWord, language: self.translationLanguage) {
                        self.speechService.speak(translatedWord, language: self.translationLanguage.languageCode)
                    }
                }
                translationWorkItem = workItem

                // Schedule the translation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: workItem)
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

