//
//  Event.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//
import Cocoa
import Carbon
import AVFoundation
import Foundation
import CoreGraphics
import Sauce

extension CGEventFlags {
    var toNSEventModifierFlags: NSEvent.ModifierFlags {
        var nsFlags = NSEvent.ModifierFlags()
        
        if contains(.maskShift) {
            nsFlags.insert(.shift)
        }
        if contains(.maskControl) {
            nsFlags.insert(.control)
        }
        if contains(.maskAlternate) {
            nsFlags.insert(.option)
        }
        if contains(.maskCommand) {
            nsFlags.insert(.command)
        }
        if contains(.maskNumericPad) {
            nsFlags.insert(.numericPad)
        }
        if contains(.maskSecondaryFn) {
            nsFlags.insert(.function)
        }
        if contains(.maskAlphaShift) {
            nsFlags.insert(.capsLock)
        }
        
        return nsFlags
    }
}

class EventEffectHandler {
    let synth = AVSpeechSynthesizer()
    func handle(event: CGEvent, eventType: CGEventType, selectedLockEffect: LockEffect) {
        debugPrint("speaking handle ------- \(selectedLockEffect)")
        // guard eventType == .keyUp else { return }
        guard let str = getString(event: event, eventType: eventType) else { return }
        debugPrint("speaking ------- \(str)")
        let utterance = AVSpeechUtterance(string: str)
        let language =  Locale.preferredLanguages[0]
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        
        debugPrint("speaking ------- \(language)")
        
        switch selectedLockEffect {
        case .speakTheKey:
            synth.speak(utterance)
        case .speakAKeyWord:
            synth.speak(AVSpeechUtterance(string: getRandomWord(forKey: str)))
        default:
            break
        }
        
    }
    
    func getString(event: CGEvent, eventType: CGEventType) -> String? {
        return Sauce.shared.character(
            for: Int(event.getIntegerValueField(.keyboardEventKeycode)),
            cocoaModifiers: event.flags.toNSEventModifierFlags
        )
    }
    
    private let wordCache: [String: [String]] = {
           let wordPath = "/usr/share/dict/words"
           guard let contents = try? String(contentsOfFile: wordPath) else { return [:] }
           
           var cache: [String: [String]] = [:]
           let words = contents.components(separatedBy: .newlines)
           
           for word in words {
               guard let first = word.first?.lowercased() else { continue }
               let key = String(first)
               cache[key, default: []].append(word)
           }
           return cache
       }()
       
    func getRandomWord(forKey key: String) -> String {
        let key = key.lowercased()
        // debugPrint("getWord ------- \(key) -- \(wordCache[key])")
        guard let words = wordCache[key],
              let randomWord = words.randomElement() else {
            return key
        }
        
        return randomWord
    }
          
}
