//
//  EventHandler.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import Foundation
import CoreGraphics
import AppKit
import ApplicationServices

class EventHandler: ObservableObject {
    private let lock = NSLock()
    let effectCoordinator: EffectCoordinator
    private let throttleManager: ThrottleManager
    private var eventLoopStarted = false
    private var eventTap : CFMachPort?

    @Published var selectedLockEffect: LockEffect = .none
    @Published var selectedTranslationLanguage: TranslationLanguage = .none {
        didSet {
            effectCoordinator.translationLanguage = selectedTranslationLanguage
        }
    }
    @Published var isLocked = true {
        didSet {
            if isLocked {
                startEventLoop()
            }
        }
    }
    @Published var accessibilityPermissionGranted = false
    @Published var lastKeyString: String = "a" // fix onReceive won't work as expected for first key press

    static let shared = EventHandler()

    init(isLocked: Bool = true,
         effectCoordinator: EffectCoordinator = EffectCoordinator(),
         throttleManager: ThrottleManager = ThrottleManager()) {
        self.effectCoordinator = effectCoordinator
        self.throttleManager = throttleManager
        self.isLocked = isLocked
        self.accessibilityPermissionGranted = requestAccessibilityPermissions()
        if !self.accessibilityPermissionGranted {
            self.isLocked = false
        }
        self.lastKeyString = lastKeyString
    }

    func setLocked(isLocked: Bool) {
        if (isLocked && accessibilityPermissionGranted) {
            self.isLocked = true
            startEventLoop()
        } else {
            self.isLocked = false
        }
    }

    func checkAccessibilityPermission(){
        debugLog("------ Checking Accessibility Permission ------")
        if eventTap != nil && !CGEvent.tapIsEnabled(tap: eventTap!) {
            debugLog("Event tap disabled, attempting restart...")
            setupEventTap()
        }
        let processTrusted = AXIsProcessTrusted()
        if !processTrusted && self.accessibilityPermissionGranted {
            self.stop()
            // Handle permission loss (display alert, disable features, etc.)
            self.accessibilityPermissionGranted = false
            NSApplication.shared.terminate(self)
        }
        if processTrusted {
            self.accessibilityPermissionGranted = true
        }
        DispatchQueue.global(qos: .background).async {
          // Schedule the next check
            let delay = DispatchTimeInterval.seconds(3)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.checkAccessibilityPermission()
            }
        }
    }

    func run() {
        checkAccessibilityPermission()

        if requestAccessibilityPermissions() {
            startEventLoop()
        } else {
            self.accessibilityPermissionGranted = false
            self.isLocked = false
            debugLog("Please grant accessibility permissions in System Preferences")
        }
    }

    func stop(){
        isLocked = false
        CFRunLoopStop(CFRunLoopGetCurrent())
    }

    func startEventLoop() {
        if(eventLoopStarted) { return }
        if(!accessibilityPermissionGranted) { return }
        lock.lock()
        defer { lock.unlock() }

        setupEventTap() // Setup event tap to capture key events
        DispatchQueue.main.async {
            self.eventLoopStarted = true
            CFRunLoopRun()  // Start the run loop to handle events in a background thread
        }
    }

    private func setupEventTap() {
        let eventMask = CGEventMask(
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << 14) // search and voice key
        )

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: globalKeyEventHandler,
            userInfo: UnsafeMutableRawPointer(Unmanaged
                .passUnretained(self)
                .toOpaque())
        )

        guard eventTap != nil else {
            fatalError("Failed to create event tap")
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0
        )
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap!, enable: true)
    }

    func handleKeyEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>?{

        // Handle tap disable events first
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            debugLog("Event tap disabled, attempting to re-enable...")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        debugLog("--- keyup/down: \(type == .keyDown || type == .keyUp), keyboardEventKeyboardType: \(event.getIntegerValueField(.keyboardEventKeyboardType))")
        // disable media keys, power button
        if isLocked && event.getIntegerValueField(.keyboardEventKeyboardType) == 0 {
            return nil
        }
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let controlFlag = event.flags.contains(.maskControl)
        let optionFlag = event.flags.contains(.maskAlternate)
        let eventType = type == .keyDown ? "pressed" : "released"
        debugLog("Key Code: \0x\(String(keyCode, radix: 16)),\t" +
                 "Control Flag: \(controlFlag),\t" +
                 "Event Type: (\(type.rawValue)) \(eventType)")
        // Toggle with Ctrl + Option + U
        if optionFlag && controlFlag && keyCode == KeyCode.u.rawValue && type == .keyDown {
            debugLog("Keyboard locked: \(isLocked)")
            self.isLocked = isLocked ? false : true
            CFRunLoopStop(CFRunLoopGetCurrent())

            return nil
        }

        if isLocked {

            if type != .keyUp { return nil }

            if throttleManager.isThrottled() { return nil }

            self.lastKeyString = effectCoordinator.handle(
                event: event, eventType: type, selectedLockEffect: selectedLockEffect
            )
            debugLog("keyup------- \(lastKeyString), str: \(lastKeyString)")
            return nil
        } else {
            return Unmanaged.passRetained(event)
        }
    }

    func requestAccessibilityPermissions() -> Bool {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            DispatchQueue.main.async {
                let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
                AXIsProcessTrustedWithOptions(options)
            }
        }
        return trusted
    }

}

func globalKeyEventHandler(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
    let mySelf = Unmanaged<EventHandler>.fromOpaque(refcon).takeUnretainedValue()
    return mySelf.handleKeyEvent(proxy: proxy, type: type, event: event)
}

