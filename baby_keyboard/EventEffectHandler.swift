//
//  Event.swift
//  baby_keyboard
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
    func handle(event: CGEvent, eventType: CGEventType) {
        guard eventType == .keyUp else { return }
        guard let str = getString(event: event, eventType: eventType),
              str.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: str)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        synth.speak(utterance)
    }
    
    func getString(event: CGEvent, eventType: CGEventType) -> String? {
        return Sauce.shared.character(
            for: Int(event.getIntegerValueField(.keyboardEventKeycode)),
            cocoaModifiers: event.flags.toNSEventModifierFlags
        )
    }
}
