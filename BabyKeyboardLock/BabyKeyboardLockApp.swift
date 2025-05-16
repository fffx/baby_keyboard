//
//  BabyKeyboardLockApp.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
import Combine

let AnimationWindowID = "animationTransparentWindow"
let WordDisplayWindowID = "wordDisplayTransparentWindow"
let VisualEffectsWindowID = "visualEffectsTransparentWindow"
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
    private var cancellables = Set<AnyCancellable>()
    private var screenObserver: Any?
    
    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// <#Description#>
    /// - Parameter notification: <#notification description#>
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        // Add screen configuration change observer
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateWindowFrames()
            }
        }

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
            
            // Create the animation window for confetti animations
            let animationWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: NSScreen.main?.frame.width ?? 1200, height: NSScreen.main?.frame.height ?? 800),
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            animationWindow.identifier = NSUserInterfaceItemIdentifier(AnimationWindowID)
            animationWindow.backgroundColor = .clear
            animationWindow.isReleasedWhenClosed = false
            animationWindow.center()
            animationWindow.setFrameAutosaveName("Animation Window")
            animationWindow.contentView = NSHostingView(rootView: AnimationView())
            animationWindow.orderFrontRegardless()
            
            // Create the word display window for showing words and translations
            let wordDisplayWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: NSScreen.main?.frame.width ?? 1200, height: NSScreen.main?.frame.height ?? 800),
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            wordDisplayWindow.identifier = NSUserInterfaceItemIdentifier(WordDisplayWindowID)
            wordDisplayWindow.backgroundColor = .clear
            wordDisplayWindow.isReleasedWhenClosed = false
            wordDisplayWindow.center()
            wordDisplayWindow.setFrameAutosaveName("Word Display Window")
            wordDisplayWindow.contentView = NSHostingView(rootView: WordDisplayView())
            wordDisplayWindow.level = .floating // Ensure it appears above other windows
            wordDisplayWindow.ignoresMouseEvents = true // Prevent mouse interaction
            wordDisplayWindow.titlebarAppearsTransparent = true
            wordDisplayWindow.orderFrontRegardless()
            
            // Create the visual effects window for additional animations
            let visualEffectsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: NSScreen.main?.frame.width ?? 1200, height: NSScreen.main?.frame.height ?? 800),
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            visualEffectsWindow.identifier = NSUserInterfaceItemIdentifier(VisualEffectsWindowID)
            visualEffectsWindow.backgroundColor = .clear
            visualEffectsWindow.isReleasedWhenClosed = false
            visualEffectsWindow.center()
            visualEffectsWindow.setFrameAutosaveName("Visual Effects Window")
            visualEffectsWindow.contentView = NSHostingView(rootView: VisualEffectsView())
            visualEffectsWindow.level = .floating 
            visualEffectsWindow.ignoresMouseEvents = true
            visualEffectsWindow.titlebarAppearsTransparent = true
            visualEffectsWindow.orderFrontRegardless()
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
            // if popover.isShown {
            //     hidePopover()
            // } else {
                showPopover()
            // }
        default:
            return
        }
    }
    
    private func updateWindowFrames() {
        guard let mainScreen = NSScreen.main else { return }
        let frame = NSRect(x: 0, y: 0, width: mainScreen.frame.width, height: mainScreen.frame.height)
        
        // Update all transparent windows
        NSApp.windows.forEach { window in
            if let identifier = window.identifier?.rawValue,
               [AnimationWindowID, WordDisplayWindowID, VisualEffectsWindowID].contains(identifier) {
                window.setFrame(frame, display: true)
            }
        }
    }
}
