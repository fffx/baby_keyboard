//
//  BabyKeyboardLockApp.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
import Combine

let AnimationWindowID = "animationTransparentWindow"
let MainWindowID = "main"

@main
struct BabyKeyboardLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isLaunched: Bool = false
    
    @AppStorage("lockKeyboardOnLaunch") var lockKeyboardOnLaunch = false
    @AppStorage("selectedLockEffect") var selectedLockEffect: LockEffect = .none
    @AppStorage("selectedTranslationLanguage") var selectedTranslationLanguage: TranslationLanguage = .none
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared

    var body: some Scene {
        Group { }
    }
    
    init() {
        eventHandler.setLocked(isLocked: lockKeyboardOnLaunch)
        eventHandler.selectedLockEffect = selectedLockEffect
        eventHandler.selectedTranslationLanguage = selectedTranslationLanguage
    }
}

// hide from dock
// https://stackoverflow.com/questions/70697737/hide-app-icon-from-macos-menubar-on-launch
// https://stackoverflow.com/questions/68884499/make-swiftui-app-appear-in-the-macos-dock
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>() // Add this property
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
//        NSApplication.shared.setActivationPolicy(.regular)
//        NSApplication.shared.activate(ignoringOtherApps: true)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(named: EventHandler.shared.isLocked ? "keyboard.locked" : "keyboard.unlocked")
            statusButton.image?.accessibilityDescription = Bundle.applicationName
            statusButton.sendAction(on: [.rightMouseUp, .leftMouseUp])  // Only trigger on mouse click
            statusButton.target = self
            statusButton.action = #selector(handleStatusBarClick)
        }
        
        // Add observer for isLocked changes
        EventHandler.shared.$isLocked
            .sink { [weak self] isLocked in
                if let statusButton = self?.statusItem.button {
                    statusButton.image = NSImage(named: isLocked ? "keyboard.locked" : "keyboard.unlocked")
                }
            }
            .store(in: &cancellables)
        
        self.popover = NSPopover()
        // self.popover.contentSize = NSSize(width: 300, height: 400)
        // self.popover.appearance = NSAppearance(named: .accessibilityHighContrastVibrantLight)
        self.popover.behavior = .transient
        let rootView = ContentView(eventHandler: EventHandler.shared)
        let nSHostingController = NSHostingController(rootView: rootView)
        
        // nSHostingController.preferredContentSize = NSSize(width: 300, height: 300)
        
        self.popover.contentViewController = nSHostingController
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.showPopover()
            EventHandler.shared.run()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        EventHandler.shared.stop()
        debugPrint("-------- applicationWillTerminate --------")
    }
    
    func showPopover(){
        if let button = statusItem.button {
            // Get the actual menu bar height
            let menuBarHeight = NSStatusBar.system.thickness
            
            // Create properly adjusted bounds
            var adjustedBounds = button.bounds
            adjustedBounds.origin.y -= menuBarHeight * 0.1
            popover.show(relativeTo: adjustedBounds, of: button, preferredEdge: .minY)
            
            // Make the popover's window active
            if let window = popover.contentViewController?.view.window {
                window.makeKey()
            }
        }
    }
    
    func hidePopover() {
        if popover.isShown {
            self.popover.performClose(nil)
        }
    }
    
    @objc func handleStatusBarClick(_ sender: NSStatusBarButton? = nil) {
        guard let event = NSApp.currentEvent else { return }
        
        switch event.type {
        case .leftMouseUp:
            EventHandler.shared.setLocked(isLocked: !EventHandler.shared.isLocked)
        case .rightMouseUp:
            if popover.isShown {
                hidePopover()
            } else {
                showPopover()
            }
        default:
            return
        }
    }
}
