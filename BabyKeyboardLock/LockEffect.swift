//
//  SoundEffect.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 24.12.2024.
//
import SwiftUI

enum LockEffect: String, CaseIterable, Identifiable{
    case none = "LockEffect.none"
    case confettiConnon = "LockEffect.confettiCannon"
    case speakTheKey = "LockEffect.speakTheKey"
    case speakAKeyWord = "LockEffect.speakAKeyWord"
    // TODO add random
    
    var id: Self {
        return self
    }
    
    var localizedString: String {
        NSLocalizedString(self.rawValue, comment: "Lock effect option")
    }
}

enum TranslationLanguage: String, CaseIterable, Identifiable {
    case none = "TranslationLanguage.none"
    case french = "TranslationLanguage.french"
    case russian = "TranslationLanguage.russian"
    case german = "TranslationLanguage.german"
    
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
        }
    }
}

