//
//  DebugLogger.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 20.12.2024.
//

import Foundation

// Debug print helper - only prints in DEBUG builds
func debugLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}

