//
//  SoundEffect.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 24.12.2024.
//
import SwiftUI

enum LockEffect: String, CaseIterable, Identifiable {
    case basso = "LockEffect.basso"
    case glass = "LockEffect.glass"
    case ping = "LockEffect.ping"
    case sosumi = "LockEffect.sosumi"
    case submarine = "LockEffect.submarine"
    case tink = "LockEffect.tink"
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

    var soundName: String? {
        switch self {
        case .basso:
            return "Basso"
        case .glass:
            return "Glass"
        case .ping:
            return "Ping"
        case .sosumi:
            return "Sosumi"
        case .submarine:
            return "Submarine"
        case .tink:
            return "Tink"
        default:
            return nil
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
