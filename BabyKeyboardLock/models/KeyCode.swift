//
//  KeyCode.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import CoreGraphics

enum KeyCode: CGKeyCode, CaseIterable, Identifiable {
    case u = 0x20
    case delete = 0x33
    case up = 0x7e
    case left = 0x7b
    case right = 0x7c
    case down = 0x7d
    case escape = 0x35
    case tab = 0x30
    case enter = 0x24

    var id: Self {
        return self
    }
}

