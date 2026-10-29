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
        guard let str = getString(event: event, eventType: eventType) else { return "" }
        return handle(keyString: str, selectedLockEffect: selectedLockEffect)
    }

    func handle(keyString: String, selectedLockEffect: LockEffect) -> String {
        debugLog("speaking handle ------- \(selectedLockEffect)")
        debugLog("get key name ------- \(keyString)")

        switch selectedLockEffect {
        case .speakTheKey:
            speechService.speak(keyString)
        case .speakAKeyWord:
            let randomWord = wordService.getRandomWord(forKey: keyString)
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

        return keyString
    }

    func getString(event: CGEvent, eventType: CGEventType) -> String? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if KeyCode.allCases.contains(where: { $0.rawValue == keyCode }) {
            let key = KeyCode(rawValue: CGKeyCode(keyCode))!
            if key == .capsLock {
                return "caps lock"
            }
            return String(describing: key)
        }

        // Sauce uses TIS APIs which must be called from the main thread
        // The event tap callback runs on a background thread, so we need to dispatch synchronously
        let keyCodeInt = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = event.flags.toNSEventModifierFlags
        
        var result: String?
        if Thread.isMainThread {
            result = Sauce.shared.character(for: keyCodeInt, cocoaModifiers: modifiers)
        } else {
            DispatchQueue.main.sync {
                result = Sauce.shared.character(for: keyCodeInt, cocoaModifiers: modifiers)
            }
        }
        return result
    }
}

