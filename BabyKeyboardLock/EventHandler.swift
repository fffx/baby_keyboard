import Foundation
import CoreGraphics
import AppKit
import ApplicationServices
import CoreData
import SwiftData
import Combine

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
    @Published var isLocked = true {
        didSet {
            if isLocked {
                startEventLoop()
            }
        }
    }
    @Published var accessibilityPermissionGranted = false
    @Published var lastKeyString: String = "a" // fix onReceive won't work as expected for first key press

    private var lastEventTime: Date = Date()
    private let throttleInterval: TimeInterval = 1 // seconds
    private func isThrottled() -> Bool {
        let now = Date()
        let timeSinceLastEvent = now.timeIntervalSince(lastEventTime)
      
        if timeSinceLastEvent >= throttleInterval {
            lastEventTime = now
            return false
        }
        debugPrint("Throttled >>>>> timeSinceLastEvent: \(timeSinceLastEvent)")
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
        
        // Initialize wordSetType from UserDefaults
        if let savedTypeRaw = UserDefaults.standard.string(forKey: "selectedWordSetType"),
           let savedType = WordSetType(rawValue: savedTypeRaw) {
            self.selectedWordSetType = savedType
        }
        eventEffectHandler.setWordSetType(self.selectedWordSetType)
        
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
            startEventLoop()
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
            debugPrint("Please grant accessibility permissions in System Preferences")
            // exit(EXIT_SUCCESS)
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
            (1 << 14) // seacrh and voice key
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
            debugPrint("Event tap disabled, attempting to re-enable...")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        debugPrint("--- keyup/down: \(type == .keyDown || type == .keyUp), keyboardEventKeyboardType: \(event.getIntegerValueField(.keyboardEventKeyboardType))")
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
        debugPrint("Key Code: \0x\(String(keyCode, radix: 16)),\t" +
                 "Control Flag: \(controlFlag),\t" +
                 "Event Type: (\(type.rawValue)) \(eventType)")
        // Toggle with Ctrl + Option + U
        if optionFlag && controlFlag && keyCode == KeyCode.u.rawValue && type == .keyDown {
            debugPrint("Keyboard locked: \(isLocked)")
            self.isLocked = isLocked ? false : true
            CFRunLoopStop(CFRunLoopGetCurrent())
            
            return nil
        }

        if isLocked {
            
            if type != .keyUp { return nil }
            
            if isThrottled() { return nil }
            
            self.lastKeyString = eventEffectHandler.handle(
                event: event, eventType: type, selectedLockEffect: selectedLockEffect
            )
            debugPrint("keyup------- \(lastKeyString), str: \(lastKeyString)")
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

