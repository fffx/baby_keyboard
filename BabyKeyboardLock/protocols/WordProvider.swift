//
//  WordProvider.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Foundation

protocol WordProvider {
    func getRandomWord(forKey key: String) -> String
    func getTranslation(word: String, language: TranslationLanguage) -> String?
}

