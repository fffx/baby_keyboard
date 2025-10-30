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
    private let eventTapManager: EventTapManaging
    private var eventLoopStarted = false
    private var eventTap : CFMachPort?
    private var permissionCheckWorkItem: DispatchWorkItem?

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

    // Helper to detect if running in test or preview environment
    private static var isRunningTestsOrPreview: Bool {
        #if DEBUG
        // Check if we're in a test bundle (most reliable)
        let isTestBundle = Bundle.main.bundlePath.hasSuffix(".xctest") ||
                          Bundle.main.bundlePath.contains("XCTestProducts") ||
                          Bundle(for: EventHandler.self).bundlePath.contains("Tests")

        // Check for XCTest
        let isXCTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                       NSClassFromString("XCTest") != nil

        // Check for Swift Testing framework
        let isSwiftTesting = NSClassFromString("Testing.Test") != nil ||
                            ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil ||
                            ProcessInfo.processInfo.arguments.contains { $0.contains("xctest") }

        // Check for SwiftUI Previews
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

        return isTestBundle || isXCTest || isSwiftTesting || isPreview
        #else
        return false
        #endif
    }

    init(isLocked: Bool = true,
         effectCoordinator: EffectCoordinator = EffectCoordinator(),
         throttleManager: ThrottleManager = ThrottleManager(),
         eventTapManager: EventTapManaging? = nil) {
        self.effectCoordinator = effectCoordinator
        self.throttleManager = throttleManager

        // Determine which event tap manager to use
        let isTestMode = Self.isRunningTestsOrPreview
        debugLog("EventHandler init - Test mode: \(isTestMode)")

        // Use MockEventTapManager in tests, DefaultEventTapManager in production
        self.eventTapManager = eventTapManager ?? (isTestMode ? MockEventTapManager() : DefaultEventTapManager())
        self.isLocked = isLocked

        // Skip accessibility check if running tests or previews
        self.accessibilityPermissionGranted = isTestMode ? true : requestAccessibilityPermissions()

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
        if Self.isRunningTestsOrPreview { return }
        debugLog("------ Checking Accessibility Permission ------")
        if eventTap != nil && !eventTapManager.isTapEnabled(eventTap) {
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

        // Cancel any existing scheduled check to prevent memory accumulation
        permissionCheckWorkItem?.cancel()

        // Create a new work item for the next check
        let workItem = DispatchWorkItem { [weak self] in
            self?.checkAccessibilityPermission()
        }
        permissionCheckWorkItem = workItem

        // Schedule the next check
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }

    func run() {
        // Skip permission checks in test or preview environment
        if Self.isRunningTestsOrPreview {
            return
        }

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

        // Cancel any pending permission checks to prevent memory leaks
        permissionCheckWorkItem?.cancel()
        permissionCheckWorkItem = nil

        eventTapManager.stopRunLoop()
    }

    deinit {
        // Clean up resources on deallocation
        permissionCheckWorkItem?.cancel()
        permissionCheckWorkItem = nil

        if let eventTap = eventTap {
            eventTapManager.enableTap(eventTap, enable: false)
            // CFMachPort is auto-released in ARC
        }
        eventTap = nil
    }

    func startEventLoop() {
        if(eventLoopStarted) { return }
        if(!accessibilityPermissionGranted) { return }
        lock.lock()
        defer { lock.unlock() }

        setupEventTap() // Setup event tap to capture key events
        DispatchQueue.main.async {
            self.eventLoopStarted = true
            self.eventTapManager.runLoop()  // Start the run loop to handle events in a background thread
        }
    }

    private func setupEventTap() {
        let eventMask = CGEventMask(
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << 14) // search and voice key
        )

        eventTap = eventTapManager.createEventTap(
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
            // In test/preview mode, event tap creation may return nil (mock)
            // Don't crash the app in this case
            if !Self.isRunningTestsOrPreview {
                fatalError("Failed to create event tap")
            }
            debugLog("Event tap is nil (test/preview mode)")
            return
        }

        let runLoopSource = eventTapManager.createRunLoopSource(eventTap)
        eventTapManager.addSourceToRunLoop(runLoopSource)
        eventTapManager.enableTap(eventTap, enable: true)
    }

    func handleKeyEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>?{

        // Handle tap disable events first
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            debugLog("Event tap disabled, attempting to re-enable...")
            eventTapManager.enableTap(eventTap, enable: true)
            return Unmanaged.passUnretained(event)
        }

        debugLog("--- keyup/down: \(type == .keyDown || type == .keyUp), keyboardEventKeyboardType: \(event.getIntegerValueField(.keyboardEventKeyboardType))")
        // disable media keys, power button
        if isLocked && event.getIntegerValueField(.keyboardEventKeyboardType) == 0 {
            return nil
        }
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
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
            eventTapManager.stopRunLoop()

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
            return Unmanaged.passUnretained(event)
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

    #if DEBUG
    // MARK: - Test Helpers
    // These methods are only available in DEBUG builds for testing purposes

    /// Returns whether the event tap has been set up
    var isEventTapSetup: Bool {
        return eventTap != nil
    }

    /// Exposes the event tap for testing purposes
    var testEventTap: CFMachPort? {
        return eventTap
    }

    /// Exposes the event tap manager for testing purposes
    var testEventTapManager: EventTapManaging {
        return eventTapManager
    }

    /// Allows tests to manually trigger setupEventTap without starting the run loop
    func testSetupEventTap() {
        setupEventTap()
    }

    /// Allows tests to clear the event tap (useful for cleanup)
    func testClearEventTap() {
        eventTapManager.enableTap(eventTap, enable: false)
        eventTap = nil
    }
    #endif

}

func globalKeyEventHandler(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
    let mySelf = Unmanaged<EventHandler>.fromOpaque(refcon).takeUnretainedValue()
    return mySelf.handleKeyEvent(proxy: proxy, type: type, event: event)
}

