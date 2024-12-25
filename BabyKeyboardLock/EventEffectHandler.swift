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
    let simpleWordsMap: [String: [String]] = [
        "a": ["apple", "ant", "air", "arm", "axe", "all", "ask", "and", "add"],
        "b": ["ball", "bat", "bag", "bed", "bear", "bug", "bun", "bus", "big", "bit"],
        "c": ["cat", "car", "cow", "cup", "cap", "can", "cut", "cry", "corn"],
        "d": ["dog", "duck", "dot", "dig", "doll", "dip", "day", "den", "dam"],
        "e": ["egg", "ear", "eat", "end", "eye", "elf", "eel", "edge", "easy"],
        "f": ["fish", "fan", "fog", "fat", "fit", "fig", "fun", "far", "fox"],
        "g": ["goat", "gum", "gap", "got", "gun", "gas", "gut", "gig", "go"],
        "h": ["hat", "hen", "hop", "hit", "hug", "hot", "hip", "hum", "hut"],
        "i": ["ice", "ink", "igloo", "ill", "inn", "it", "is", "if", "in"],
        "j": ["jam", "jug", "jet", "job", "jog", "jaw", "joy", "jump", "jot"],
        "k": ["kite", "key", "kid", "kit", "king", "kick", "kind", "keep", "kitty"],
        "l": ["lion", "leg", "lip", "lap", "log", "let", "lot", "low", "lid"],
        "m": ["moon", "man", "map", "mug", "mat", "mix", "mud", "mom", "me", "mad"],
        "n": ["nest", "net", "nap", "nut", "nod", "new", "not", "no", "nice"],
        "o": ["owl", "ox", "oil", "odd", "off", "old", "on", "out", "oak"],
        "p": ["pig", "pen", "pot", "pan", "pet", "pin", "pop", "pit", "pat"],
        "q": ["queen", "quilt", "quiz", "quick", "quit", "quack", "quest"],
        "r": ["rat", "rug", "run", "red", "row", "rip", "rob", "ram", "rod"],
        "s": ["sun", "sit", "sip", "sad", "sow", "set", "saw", "sea", "six"],
        "t": ["top", "tap", "tin", "toy", "tip", "tag", "tub", "tan", "ten"],
        "u": ["umbrella", "up", "use", "us", "urn", "ugly", "unit"],
        "v": ["van", "vet", "vase", "vat", "vie", "via", "vest", "vivid"],
        "w": ["wet", "win", "wig", "wax", "way", "wow", "web", "was", "will"],
        "x": ["x-ray", "xylophone", "xenon"],
        "y": ["yak", "yes", "yarn", "yell", "yet", "yum", "you", "young"],
        "z": ["zebra", "zip", "zap", "zig", "zoo", "zen", "zero", "zone"]
    ]
    let synth = AVSpeechSynthesizer()
    func handle(event: CGEvent, eventType: CGEventType, selectedLockEffect: LockEffect) -> String? {
        debugPrint("speaking handle ------- \(selectedLockEffect)")
        // guard eventType == .keyUp else { return }
        guard let str = getString(event: event, eventType: eventType) else { return nil }
        debugPrint("speaking ------- \(str)")
        let utterance = AVSpeechUtterance(string: str)
        let language =  Locale.preferredLanguages[0]
        
        // https://stackoverflow.com/questions/37512621/avspeechsynthesizer-change-voice
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        
        debugPrint("speaking ------- \(language)")
        
        switch selectedLockEffect {
        case .speakTheKey:
            DispatchQueue.global(qos: .background).async {
                self.synth.speak(utterance)
            }
        case .speakAKeyWord:
            let randomword = getRandomWord(forKey: str)
            synth.speak(AVSpeechUtterance(string: randomword))
            return randomword
        default:
            break
        }
        
        return str
    }
    
    func getString(event: CGEvent, eventType: CGEventType) -> String? {
        return Sauce.shared.character(
            for: Int(event.getIntegerValueField(.keyboardEventKeycode)),
            cocoaModifiers: event.flags.toNSEventModifierFlags
        )
    }
    
    func getRandomWord(forKey key: String) -> String {
        let key = key.lowercased()
        // debugPrint("getWord ------- \(key) -- \(wordCache[key])")
        guard let words = simpleWordsMap[key],
              let randomWord = words.randomElement() else {
            return key
        }
        
        debugPrint("getWord ------- \(key) -- \(randomWord)")
        return randomWord
    }
          
}
