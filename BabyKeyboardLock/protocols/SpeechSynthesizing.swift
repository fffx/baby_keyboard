//
//  SpeechSynthesizing.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import AVFoundation

protocol SpeechSynthesizing {
    var isSpeaking: Bool { get }
    func speak(_ utterance: AVSpeechUtterance)
    @discardableResult
    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool
}

extension AVSpeechSynthesizer: SpeechSynthesizing {}

