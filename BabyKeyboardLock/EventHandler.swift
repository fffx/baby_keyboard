import Foundation
import CoreGraphics
import AppKit
import ApplicationServices
import CoreData
import SwiftData
import Combine
import AVFoundation

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

class EventHandler: ObservableObject {
    private let lock = NSLock()
    let eventEffectHandler = EventEffectHandler()
    private var eventLoopStarted = false
    private var eventTap : CFMachPort?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var selectedLockEffect: LockEffect = .none
    @Published var selectedTranslationLanguage: TranslationLanguage = .none {
        didSet {
            eventEffectHandler.translationLanguage = selectedTranslationLanguage
        }
    }
    @Published var selectedWordSetType: WordSetType = .randomShortWords {
        didSet {
            eventEffectHandler.setWordSetType(selectedWordSetType)
        }
    }
    @Published var usePersonalVoice: Bool = false {
        didSet {
            eventEffectHandler.usePersonalVoice = usePersonalVoice
            if usePersonalVoice {
                requestPersonalVoicePermission()
            }
        }
    }
    @Published var isLocked = true
    @Published var accessibilityPermissionGranted = false
    @Published var personalVoiceAvailable: Bool = false
    @Published var lastKeyString: String = "a" // fix onReceive won't work as expected for first key press

    private var lastEventTime: Date = Date()
    @Published var throttleInterval: TimeInterval = 1.0 // seconds (for visual effects)
    @Published var wordsThrottleInterval: TimeInterval = 1.5 // seconds (for word effects)
    @Published var confettiFadeTime: TimeInterval = 3.0 // seconds
    @Published var wordTranslationDelay: TimeInterval = 0.8 // seconds
    
    private func isThrottled(effectType: LockEffect) -> Bool {
        let now = Date()
        let timeSinceLastEvent = now.timeIntervalSince(lastEventTime)
        
        // Use different throttle intervals based on effect category
        let currentThrottleInterval = effectType.category == .words ? wordsThrottleInterval : throttleInterval
      
        if timeSinceLastEvent >= currentThrottleInterval {
            lastEventTime = now
            return false
        }
        debugPrint("Throttled >>>>> timeSinceLastEvent: \(String(format: "%.2f", timeSinceLastEvent)), threshold: \(String(format: "%.2f", currentThrottleInterval))")
        return true
    }
    
    static let shared = EventHandler()
    
    init(isLocked: Bool = true) {
        self.isLocked = isLocked
        self.accessibilityPermissionGranted = requestAccessibilityPermissions()
        if !self.accessibilityPermissionGranted {
            self.isLocked = false
        }
        self.lastKeyString = lastKeyString
        
        // Initialize throttle interval from UserDefaults
        self.throttleInterval = UserDefaults.standard.double(forKey: "throttleInterval")
        if self.throttleInterval == 0 { // If not set yet
            self.throttleInterval = 1.0
        }
        
        // Initialize words throttle interval from UserDefaults
        self.wordsThrottleInterval = UserDefaults.standard.double(forKey: "wordsThrottleInterval")
        if self.wordsThrottleInterval == 0 { // If not set yet
            self.wordsThrottleInterval = 1.5
        }
        
        // Initialize fade time from UserDefaults
        self.confettiFadeTime = UserDefaults.standard.double(forKey: "confettiFadeTime")
        if self.confettiFadeTime == 0 { // If not set yet
            self.confettiFadeTime = 3.0
        }

        // Initialize word translation delay from UserDefaults
        self.wordTranslationDelay = UserDefaults.standard.double(forKey: "wordTranslationDelay")
        if self.wordTranslationDelay == 0 { // If not set yet
            self.wordTranslationDelay = 0.8
        }
        
        // Initialize wordSetType from UserDefaults
        if let savedTypeRaw = UserDefaults.standard.string(forKey: "selectedWordSetType"),
           let savedType = WordSetType(rawValue: savedTypeRaw) {
            self.selectedWordSetType = savedType
        }
        eventEffectHandler.setWordSetType(self.selectedWordSetType)
        
        // Initialize personal voice setting from UserDefaults
        self.usePersonalVoice = UserDefaults.standard.bool(forKey: "usePersonalVoice")
        eventEffectHandler.usePersonalVoice = self.usePersonalVoice
        
        // Check if personal voice is available
        if self.usePersonalVoice {
            checkPersonalVoiceAvailability()
        }
        
        // Observe changes to the main words set
        NotificationCenter.default.publisher(for: .init("MainWordsUpdated"))
            .sink { [weak self] _ in
                // Refresh UI when main words change
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Observe changes to the random words list
        NotificationCenter.default.publisher(for: .init("RandomWordsUpdated"))
            .sink { [weak self] _ in
                // Refresh UI when random words change
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func setLocked(isLocked: Bool) {
        if (isLocked && accessibilityPermissionGranted) {
            self.isLocked = true
        } else {
            self.isLocked = false
        }
    }

    func checkAccessibilityPermission(){
        debugPrint("------ Checking Accessibility Permission ------")
        if eventTap != nil && !CGEvent.tapIsEnabled(tap: eventTap!) {
            print("Event tap disabled, attempting restart...")
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
            // Ensure the event loop starts after permission is granted
            if !self.eventLoopStarted {
                self.startEventLoop()
            }
            return // Stop checking once permission is granted
        }
        
        // Only continue checking if permission hasn't been granted yet
        if !self.accessibilityPermissionGranted {
            DispatchQueue.global(qos: .background).async {
                // Schedule the next check
                let delay = DispatchTimeInterval.seconds(3)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.checkAccessibilityPermission()
                }
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
            debugPrint("Please grant accessibility permissions in System Preferences")
            // exit(EXIT_SUCCESS)
        }
    }
    
    func stop(){
        isLocked = false
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        // Do not stop the main run loop; just mark our loop as stopped
        eventLoopStarted = false
    }
    
    func startEventLoop() {
        if(eventLoopStarted) { return }
        if(!accessibilityPermissionGranted) { return }
        lock.lock()
        defer { lock.unlock() }

        setupEventTap() // Setup event tap to capture key events on the current (main) run loop
        self.eventLoopStarted = true
    }
    
    private func setupEventTap() {
        // Combine all event types we want to monitor
        let eventMask = CGEventMask(
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << 14) // seacrh and voice key
        )
        
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: globalKeyEventHandler,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        guard let eventTap = eventTap else {
            fatalError("Failed to create event tap")
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0
        )
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    func handleKeyEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // Handle tap disable events first
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            debugPrint("Event tap disabled, attempting to re-enable...")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        // If not locked, pass through ALL events immediately without any processing
        guard isLocked else {
            return Unmanaged.passRetained(event)
        }
        
        // Handle keyboard events only when locked
        if type == .keyDown || type == .keyUp {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let controlFlag = event.flags.contains(.maskControl)
            let optionFlag = event.flags.contains(.maskAlternate)
            
            // Toggle keyboard lock with Ctrl + Option + U
            if optionFlag && controlFlag && keyCode == KeyCode.u.rawValue && type == .keyDown {
                debugPrint("Keyboard locked: \(isLocked)")
                self.isLocked = false
                return nil
            }

            // Handle normal keyboard events when locked
            if type != .keyUp { return nil }
            if isThrottled(effectType: selectedLockEffect) { return nil }
            
            self.lastKeyString = eventEffectHandler.handle(
                event: event, eventType: type, selectedLockEffect: selectedLockEffect
            )
            debugPrint("keyup------- \(lastKeyString)")
            return nil
        }
        
        return Unmanaged.passRetained(event)
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

    private func requestPersonalVoicePermission() {
        if #available(macOS 14.0, *) {
            AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self.personalVoiceAvailable = true
                    } else {
                        // If not authorized, disable the feature
                        self.personalVoiceAvailable = false
                        if self.usePersonalVoice {
                            // Only show message if user has explicitly enabled the feature
                            let alert = NSAlert()
                            alert.messageText = "Personal Voice Not Available"
                            alert.informativeText = "Please enable Personal Voice in System Settings > Accessibility > Personal Voice and make sure you've created a Personal Voice."
                            alert.alertStyle = .informational
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                }
            }
        } else {
            // Personal Voice is not available on this version of macOS
            self.personalVoiceAvailable = false
            if self.usePersonalVoice {
                let alert = NSAlert()
                alert.messageText = "Personal Voice Not Supported"
                alert.informativeText = "Personal Voice requires macOS 14.0 or newer."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
                
                // Disable the feature since not supported
                self.usePersonalVoice = false
            }
        }
    }
    
    private func checkPersonalVoiceAvailability() {
        if #available(macOS 14.0, *) {
            // Check if any personal voices are available
            let personalVoices = AVSpeechSynthesisVoice.speechVoices().filter { voice in
                return voice.voiceTraits.contains(.isPersonalVoice)
            }
            
            DispatchQueue.main.async {
                self.personalVoiceAvailable = !personalVoices.isEmpty
                
                // If no personal voices available but feature is enabled, show alert
                if personalVoices.isEmpty && self.usePersonalVoice {
                    let alert = NSAlert()
                    alert.messageText = "No Personal Voice Found"
                    alert.informativeText = "You need to create a Personal Voice in System Settings > Accessibility > Personal Voice before using this feature."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    
                    // Disable the feature since no voice is available
                    self.usePersonalVoice = false
                }
            }
        } else {
            // Personal Voice is not available on this version of macOS
            DispatchQueue.main.async {
                self.personalVoiceAvailable = false
                
                if self.usePersonalVoice {
                    let alert = NSAlert()
                    alert.messageText = "Personal Voice Not Supported"
                    alert.informativeText = "Personal Voice requires macOS 14.0 or newer."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    
                    // Disable the feature since not supported
                    self.usePersonalVoice = false
                }
            }
        }
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
