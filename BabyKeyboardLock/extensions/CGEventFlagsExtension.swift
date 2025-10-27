//
//  CGEventFlagsExtension.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Cocoa
import CoreGraphics

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

