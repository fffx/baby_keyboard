//
//  BabyKeyboardLockApp.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
let FireworkWindowID = "fireworkTransparentWindow"
let MainWindowID = "main"

@main
struct BabyKeyboardLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @State private var isLaunched: Bool = false
    @State var menuBarViewIsPresented: Bool = false
    
    @AppStorage("lockKeyboardOnLaunch") var lockKeyboardOnLaunch = false
    @AppStorage("selectedLockEffect") var selectedLockEffect: LockEffect = .none
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @StateObject var eventHandler: EventHandler = EventHandler.shared
    
    @State var mainWindow: NSWindow? = nil
    // var letterView: LetterView!
    var body: some Scene {
        Window("Firework window", id: FireworkWindowID) {
            FireworkView(eventHandler: eventHandler).frame(maxWidth: .infinity, maxHeight: .infinity)
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                // .disabled(true)
                .onAppear {
                    // Make the window transparent
                    guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == FireworkWindowID }) else { return }
                    // print(window.identifier!.rawValue)
                    window.isOpaque = false
                    // window.backgroundColor = NSColor.clear
                    window.level = .floating
                
                    // window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                }
        }
        .windowStyle(.hiddenTitleBar)
        // .windowResizability(.contentSize)
        
    }
    
    init() {
        eventHandler.setLocked(isLocked: lockKeyboardOnLaunch)
    }
}

// hide from dock
// https://stackoverflow.com/questions/70697737/hide-app-icon-from-macos-menubar-on-launch
// https://stackoverflow.com/questions/68884499/make-swiftui-app-appear-in-the-macos-dock
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
//        NSApplication.shared.setActivationPolicy(.regular)
//        NSApplication.shared.activate(ignoringOtherApps: true)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(named: "keyboard.locked")
            statusButton.image?.accessibilityDescription = Bundle.applicationName
            statusButton.action = #selector(togglePopover)
        }
        
        self.popover = NSPopover()
        // self.popover.contentSize = NSSize(width: 300, height: 400)
        // self.popover.appearance = NSAppearance(named: .accessibilityHighContrastVibrantLight)
        self.popover.behavior = .transient
        let nSHostingController = NSHostingController(
            rootView: ContentView(eventHandler: EventHandler.shared).background(Color(nsColor: .windowBackgroundColor))
        )
        // nSHostingController.preferredContentSize = NSSize(width: 300, height: 300)
        
        
        self.popover.contentViewController = nSHostingController
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        EventHandler.shared.stop()
        debugPrint("-------- applicationWillTerminate --------")
    }
    
    @objc func togglePopover() {
          if let button = statusItem.button {
              if popover.isShown {
                  self.popover.performClose(nil)
              } else {
                  // Get the actual menu bar height
                  let menuBarHeight = NSStatusBar.system.thickness
                  
                  // Create properly adjusted bounds
                  var adjustedBounds = button.bounds
                  adjustedBounds.origin.y -= menuBarHeight * 0.1
                  popover.show(relativeTo: adjustedBounds, of: button, preferredEdge: .minY)
              }
          }
          
      }
}
