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

class EventEffectHandler {
    let synth = AVSpeechSynthesizer()
    func handle(event: CGEvent, eventType: CGEventType) {
        guard eventType == .keyUp else { return }
        
        
        let string = Sauce.shared.character(for: Int(event.getIntegerValueField(.keyboardEventKeycode)), cocoaModifiers: [.shift])
        
        guard string != nil else { return }
        
        let utterance = AVSpeechUtterance(string: string!)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        synth.speak(utterance)
    }

    func string(from keyCode: CGKeyCode, with eventFlags: NSEvent.ModifierFlags) -> String? {
        let currentKeyboard = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        // let layoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData)?.takeUnretainedValue() as? Data

//        guard let keyboardLayout = layoutData?.withUnsafeBytes({ $0.bindMemory(to: UCKeyboardLayout.self).baseAddress }) else {
//            print("Could not get keyboard layout")
//            return nil
//        }

//        var deadKeyState: UInt32 = 0
//        let maxStringLength = 4
//        var actualStringLength = 0
//        var unicodeString: [UniChar] = Array(repeating: 0, count: maxStringLength)


        return ""
    }
}
