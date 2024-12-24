//
//  SoundEffect.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 24.12.2024.
//
enum LockEffect: String, CaseIterable, Identifiable{
    case none = "None"
    case confettiConnon = "Confetti"
    case speakTheKey = "Speak the key"
    case speakAKeyWord = "Speak a word"
    
    var id: Self {
        return self
    }

}

