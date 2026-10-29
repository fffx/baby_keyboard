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
import Combine

class EventHandler: ObservableObject {
    private let lock = NSLock()
    // Lazy initialize effect coordinator to defer loading of word/translation dictionaries
    lazy var effectCoordinator: EffectCoordinator = EffectCoordinator()
    private let throttleManager: ThrottleManager
    private let eventTapManager: EventTapManaging
    private let capsLockManager: CapsLockManaging
    private let controllerLockManager: ControllerLockManaging
    private let inputDeviceManager: InputDeviceManaging
    private var savedCapsLockState: Bool = false
    private var eventLoopStarted = false
    private var eventTap : CFMachPort?
    private var permissionCheckWorkItem: DispatchWorkItem?
    private let hotCornerService: HotCornerService
    @Published var lockedViaHotCorner = false

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
                onLocked()
            } else {
                onUnlocked()
            }
        }
    }
    @Published var accessibilityPermissionGranted = false
    @Published var lastKeyString: String = "a" // fix onReceive won't work as expected for first key press
    @Published var hotCornerEnabled: Bool = UserDefaults.standard.bool(forKey: "hotCornerEnabled") {
        didSet {
            UserDefaults.standard.set(hotCornerEnabled, forKey: "hotCornerEnabled")
            updateHotCornerService()
        }
    }

    /// Emits `isAutorepeat: Bool` whenever a key is pressed while the keyboard is locked.
    let keyPressedWhileLockedSubject = PassthroughSubject<Bool, Never>()

    #if DEBUG
    var onKeyPressedWhileLocked: ((Bool) -> Void)?
    #endif

    func notifyKeyPressed(isAutorepeat: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.keyPressedWhileLockedSubject.send(isAutorepeat)
            #if DEBUG
            self.onKeyPressedWhileLocked?(isAutorepeat)
            #endif
        }
    }

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
         effectCoordinator: EffectCoordinator? = nil,
         throttleManager: ThrottleManager = ThrottleManager(),
         eventTapManager: EventTapManaging? = nil,
         capsLockManager: CapsLockManaging? = nil,
         controllerLockManager: ControllerLockManaging? = nil,
         inputDeviceManager: InputDeviceManaging? = nil) {
        // Initialize non-lazy stored properties first
        self.throttleManager = throttleManager
        self.hotCornerService = HotCornerService()

        // Determine which managers to use
        let isTestMode = Self.isRunningTestsOrPreview
        debugLog("EventHandler init - Test mode: \(isTestMode)")

        // Use Mocks in tests, Defaults in production
        self.eventTapManager = eventTapManager ?? (isTestMode ? MockEventTapManager() : DefaultEventTapManager())
        self.capsLockManager = capsLockManager ?? (isTestMode ? MockCapsLockManager() : DefaultCapsLockManager())
        self.controllerLockManager = controllerLockManager ?? (isTestMode ? MockControllerLockManager() : DefaultControllerLockManager())
        self.inputDeviceManager = inputDeviceManager ?? (isTestMode ? MockInputDeviceManager() : InputDeviceManager.shared)
        self.isLocked = isLocked

        if let manager = self.inputDeviceManager as? InputDeviceManager {
            manager.onDeviceBlockStateChanged = { [weak self] in
                guard let self = self else { return }
                if self.isLocked {
                    self.controllerLockManager.lockControllers(matchingDevices: self.inputDeviceManager.devices)
                }
            }
        }

        // Skip accessibility check if running tests or previews
        self.accessibilityPermissionGranted = isTestMode ? true : requestAccessibilityPermissions()

        if !self.accessibilityPermissionGranted {
            self.isLocked = false
        }
        self.lastKeyString = lastKeyString

        // Allow dependency injection for testing while defaulting to lazy initialization
        if let effectCoordinator = effectCoordinator {
            self.effectCoordinator = effectCoordinator
        }

        if self.isLocked && !isTestMode {
            onLocked()
        }
    }

    func setLocked(isLocked: Bool, viaHotCorner: Bool = false) {
        if (isLocked && accessibilityPermissionGranted) {
            self.isLocked = true
            self.lockedViaHotCorner = viaHotCorner
            startEventLoop()
        } else {
            self.isLocked = false
            self.lockedViaHotCorner = false
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

        // Initialize hot corner service
        updateHotCornerService()
    }

    func stop(){
        isLocked = false
        lockedViaHotCorner = false
        eventLoopStarted = false

        // Cancel any pending permission checks to prevent memory leaks
        permissionCheckWorkItem?.cancel()
        permissionCheckWorkItem = nil

        eventTapManager.stopRunLoop()
        hotCornerService.stop()
        controllerLockManager.unlockControllers()
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
        hotCornerService.stop()
        controllerLockManager.unlockControllers()
    }

    private func updateHotCornerService() {
        if hotCornerEnabled {
            hotCornerService.start { [weak self] in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    let newState = !self.isLocked
                    debugLog("Hot corner triggered, toggling keyboard lock to: \(newState)")
                    self.setLocked(isLocked: newState, viaHotCorner: true)
                }
            }
        } else {
            hotCornerService.stop()
        }
    }

    private func onLocked() {
        savedCapsLockState = capsLockManager.getCapsLockState()
        if savedCapsLockState {
            capsLockManager.setCapsLockState(false)
        }
        controllerLockManager.lockControllers(matchingDevices: inputDeviceManager.devices)
    }

    private func onUnlocked() {
        if savedCapsLockState {
            capsLockManager.setCapsLockState(true)
            savedCapsLockState = false
        }
        controllerLockManager.unlockControllers()
    }

    func updateEventTapMaskIfNeeded() {
        // Dynamic event filtering happens per-event in handleKeyEvent
    }

    func startEventLoop() {
        if(eventLoopStarted) { return }
        if(!accessibilityPermissionGranted) { return }
        lock.lock()
        defer { lock.unlock() }
        if eventLoopStarted { return }
        eventLoopStarted = true

        // Run the event tap loop off the main thread to avoid UI stalls.
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            self.setupEventTap() // Setup event tap to capture key events
            self.eventTapManager.runLoop()  // Start the run loop on a background thread
        }
    }

    private func setupEventTap() {
        let keyboardMask: UInt32 = (1 << CGEventType.keyDown.rawValue) |
                                    (1 << CGEventType.keyUp.rawValue) |
                                    (1 << CGEventType.flagsChanged.rawValue) |
                                    (1 << 14) // search and voice key

        let m1: UInt32 = (1 << CGEventType.leftMouseDown.rawValue)
        let m2: UInt32 = (1 << CGEventType.leftMouseUp.rawValue)
        let m3: UInt32 = (1 << CGEventType.rightMouseDown.rawValue)
        let m4: UInt32 = (1 << CGEventType.rightMouseUp.rawValue)
        let m5: UInt32 = (1 << CGEventType.otherMouseDown.rawValue)
        let m6: UInt32 = (1 << CGEventType.otherMouseUp.rawValue)
        let m7: UInt32 = (1 << CGEventType.leftMouseDragged.rawValue)
        let m8: UInt32 = (1 << CGEventType.rightMouseDragged.rawValue)
        let m9: UInt32 = (1 << CGEventType.otherMouseDragged.rawValue)
        let mouseMask = m1 | m2 | m3 | m4 | m5 | m6 | m7 | m8 | m9

        let eventMask = CGEventMask(keyboardMask | mouseMask)

        debugLog("Setting up event tap with mask: \(eventMask)")

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
        proxy: CGEventTapProxy? = nil,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>?{

        // Handle tap disable events first
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            debugLog("Event tap disabled, attempting to re-enable...")
            eventTapManager.enableTap(eventTap, enable: true)
            return Unmanaged.passUnretained(event)
        }

        // Toggle with Ctrl + Option + U (always handled regardless of which keyboard)
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let controlFlag = event.flags.contains(.maskControl)
        let optionFlag = event.flags.contains(.maskAlternate)
        let eventType = type == .keyDown ? "pressed" : "released"

        if optionFlag && controlFlag && keyCode == KeyCode.u.rawValue && type == .keyDown {
            debugLog("Keyboard locked: \(isLocked)")
            self.isLocked = isLocked ? false : true
            eventTapManager.stopRunLoop()
            return nil
        }

        guard isLocked else {
            return Unmanaged.passUnretained(event)
        }

        // Check if the specific input device that originated this event is blocked
        let senderID = getSenderID(from: event)
        let shouldBlock = inputDeviceManager.isDeviceBlocked(senderID: senderID, eventType: type)
        if !shouldBlock {
            // This device is unchecked by the user, pass event through to system
            return Unmanaged.passUnretained(event)
        }

        // Handle mouse events when locked
        switch type {
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
             .otherMouseDown, .otherMouseUp, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            debugLog("Mouse event BLOCKED: \(type.rawValue), lockedViaHotCorner: \(lockedViaHotCorner), isLocked: \(isLocked)")
            return nil
        default:
            break
        }

        debugLog("Key Code: \0x\(String(keyCode, radix: 16)),\t" +
                 "Control Flag: \(controlFlag),\t" +
                 "Event Type: (\(type.rawValue)) \(eventType)")

        // disable media keys, power button
        if event.getIntegerValueField(.keyboardEventKeyboardType) == 0 {
            return nil
        }

        // Handle Caps Lock & modifier keys
        if type == .flagsChanged {
            if keyCode == KeyCode.capsLock.rawValue {
                // Prevent Caps Lock from toggling state or lighting the LED
                capsLockManager.setCapsLockState(false)

                // Strip AlphaShift flag from the event
                event.flags.remove(.maskAlphaShift)

                if !throttleManager.isThrottled() {
                    self.lastKeyString = effectCoordinator.handle(
                        event: event, eventType: type, selectedLockEffect: selectedLockEffect
                    )
                    debugLog("capsLock pressed ------- \(lastKeyString)")
                }
                notifyKeyPressed(isAutorepeat: false)
                return nil
            } else {
                // Swallow other modifier keys while locked so they don't leak to background apps
                return nil
            }
        }

        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown {
            let isAutorepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            notifyKeyPressed(isAutorepeat: isAutorepeat)
            return nil
        }

        if type != .keyUp { return nil }

        if throttleManager.isThrottled() { return nil }

        self.lastKeyString = effectCoordinator.handle(
            event: event, eventType: type, selectedLockEffect: selectedLockEffect
        )
        debugLog("keyup------- \(lastKeyString), str: \(lastKeyString)")
        return nil
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

    /// Exposes the caps lock manager for testing purposes
    var testCapsLockManager: CapsLockManaging {
        return capsLockManager
    }

    /// Exposes the controller lock manager for testing purposes
    var testControllerLockManager: ControllerLockManaging {
        return controllerLockManager
    }

    /// Exposes the saved caps lock state for testing purposes
    var testSavedCapsLockState: Bool {
        return savedCapsLockState
    }

    func testOnLocked() {
        onLocked()
    }

    func testOnUnlocked() {
        onUnlocked()
    }

    /// Allows tests to manually trigger setupEventTap without starting the run loop
    func testSetupEventTap() {
        setupEventTap()
    }

    /// Allows tests to clear the event tap (useful for cleanup)
    func testClearEventTap() {
        if let eventTap = eventTap {
            eventTapManager.enableTap(eventTap, enable: false)
            self.eventTap = nil
        }
    }

    /// Exposes inputDeviceManager for testing verification
    var testInputDeviceManager: InputDeviceManaging {
        return inputDeviceManager
    }
    #endif
}

func globalKeyEventHandler(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let handler = Unmanaged<EventHandler>
        .fromOpaque(userInfo)
        .takeUnretainedValue()

    return handler.handleKeyEvent(proxy: proxy, type: type, event: event)
}
