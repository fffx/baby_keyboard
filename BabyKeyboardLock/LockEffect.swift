//
//  SoundEffect.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 24.12.2024.
//
import SwiftUI

enum EffectCategory: String, CaseIterable, Identifiable {
    case none = "None"
    case visual = "Visual Effects"
    case words = "Words"
    case games = "Games"

    var id: Self { self }
}

enum LockEffect: String, CaseIterable, Identifiable {
    case none = "LockEffect.none"
    case confettiCannon = "LockEffect.confettiCannon"
    case speakTheKey = "LockEffect.speakTheKey"
    case speakAKeyWord = "LockEffect.speakAKeyWord"
    case speakRandomWord = "LockEffect.speakRandomWord"
    // Game modes
    case typingGame = "LockEffect.typingGame"
    // New visual effects
    case bubbles = "LockEffect.bubbles"
    case stars = "LockEffect.stars"
    case animals = "LockEffect.animals"
    case rainbowTrail = "LockEffect.rainbowTrail"
    // TODO add random

    var id: Self { self }
    
    var category: EffectCategory {
        switch self {
        case .none:
            return .none
        case .confettiCannon, .bubbles, .stars, .animals, .rainbowTrail:
            return .visual
        case .speakTheKey, .speakAKeyWord, .speakRandomWord:
            return .words
        case .typingGame:
            return .games
        }
    }
    
    var localizedString: String {
        let base = NSLocalizedString(self.rawValue, comment: "Lock effect option")
        switch self {
        case .bubbles, .stars, .animals, .rainbowTrail:
            return base + " (BETA)"
        default:
            return base
        }
    }
}

enum TranslationLanguage: String, CaseIterable, Identifiable {
    case none = "TranslationLanguage.none"
    case french = "TranslationLanguage.french"
    case russian = "TranslationLanguage.russian"
    case german = "TranslationLanguage.german"
    case spanish = "TranslationLanguage.spanish"
    case italian = "TranslationLanguage.italian"
    case japanese = "TranslationLanguage.japanese"
    case chinese = "TranslationLanguage.chinese"
    
    var id: Self {
        return self
    }
    
    var localizedString: String {
        NSLocalizedString(self.rawValue, comment: "Translation language option")
    }
    
    var languageCode: String {
        switch self {
        case .none:
            return ""
        case .french:
            return "fr-FR"
        case .russian:
            return "ru-RU"
        case .german:
            return "de-DE"
        case .spanish:
            return "es-ES"
        case .italian:
            return "it-IT"
        case .japanese:
            return "ja-JP"
        case .chinese:
            return "zh-CN"
        }
    }
}

enum WordSetType: String, CaseIterable, Identifiable {
    case randomShortWords = "WordSetType.randomShortWords"
    case mainWords = "WordSetType.mainWords"
    
    var id: Self {
        return self
    }
    
    var localizedString: String {
        NSLocalizedString(self.rawValue, comment: "Word set type option")
    }
}

// Default duration for word display in seconds
let DEFAULT_WORD_DISPLAY_DURATION: Double = 3.0

