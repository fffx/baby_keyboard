import Foundation
import CoreGraphics
import AppKit
import ApplicationServices
import CoreData

enum KeyCode: CGKeyCode {
    case u = 0x20
}

class EventHandler: ObservableObject {
    #if DEBUG
    let debug = true
    #else
    let debug = false
    #endif

    let eventEffectHandler = EventEffectHandler()
    @Published var isLocked = true
    @Published var lastKeyString: String = ""

    
    func debugLog(_ message: String) {
        if debug {
            print(message)
        }
    }
    
    func scheduleTimer(duration: Int?) {
        guard let duration = duration else { return }
        let timer = Timer(timeInterval: TimeInterval(duration),
                          repeats: false) { _ in
            let message = "Timer expired ⏱️\n"
            if let data = message.data(using: .utf8) {
                FileHandle.standardError.write(data)
            }
            
            self.isLocked = false
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
        RunLoop.current.add(timer, forMode: .common)
    }

    func run() {
        if requestAccessibilityPermissions() {
            setupEventTap() // Setup event tap to capture key events
            DispatchQueue.global(qos: .background).async {
                CFRunLoopRun()  // Start the run loop to handle events in a background thread
            }
        } else {
            print("Please grant accessibility permissions in System Preferences")
            // exit(EXIT_SUCCESS)
        }
    }
    
    func stop(){
        self.isLocked = false
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
    
    private func setupEventTap() {
        let eventMask = CGEventMask(
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << 14)
        )
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: globalKeyEventHandler,
            userInfo: UnsafeMutableRawPointer(Unmanaged
                .passUnretained(self)
                .toOpaque())
        ) else {
            fatalError("Failed to create event tap")
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    func handleKeyEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>?{
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passRetained(event)
        }
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let controlFlag = event.flags.contains(.maskControl)
        let eventType = type == .keyDown ? "pressed" : "released"
        debugLog("Key Code: \(keyCode),\t" +
                 "Control Flag: \(controlFlag),\t" +
                 "Event Type: (\(type.rawValue)) \(eventType)")
        // Checking if control+u is pressed
        if controlFlag && keyCode == KeyCode.u.rawValue && type == .keyDown {
            debugLog("Keyboard locked: \(isLocked)")
            self.isLocked = isLocked ? false : true
            CFRunLoopStop(CFRunLoopGetCurrent())
            
            return nil
        }
        
       
        if isLocked {
            if(type != .keyUp){ return nil }
            
            self.lastKeyString = eventEffectHandler.getString(event: event, eventType: type) ?? ""
            eventEffectHandler.handle(event: event, eventType: type)
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

