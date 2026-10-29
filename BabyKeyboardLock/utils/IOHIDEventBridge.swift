//
//  IOHIDEventBridge.swift
//  BabyKeyboardLock
//
//  Created by Antigravity on 29.10.2026.
//

import Foundation
import CoreGraphics
import IOKit

typealias IOHIDEventRef = UnsafeMutableRawPointer

@_silgen_name("CGEventCopyIOHIDEvent")
func CGEventCopyIOHIDEvent(_ event: CGEvent) -> IOHIDEventRef?

@_silgen_name("IOHIDEventGetSenderID")
func IOHIDEventGetSenderID(_ event: IOHIDEventRef) -> UInt64

/// Helper to get the senderID (IORegistryEntryID) from a CGEvent
func getSenderID(from event: CGEvent) -> UInt64 {
    guard let hidEvent = CGEventCopyIOHIDEvent(event) else {
        return 0
    }
    // CGEventCopyIOHIDEvent returns an unmanaged or retained reference depending on OS version;
    // in CoreGraphics C SPI it returns a reference. We obtain the sender ID:
    let senderID = IOHIDEventGetSenderID(hidEvent)
    return senderID
}
