//
//  BabyKeyboardLockApp.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
import MenuBarExtraAccess
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
    @StateObject var eventHandler: EventHandler = EventHandler()
    
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
        .windowResizability(.contentSize)
        
        MenuBarExtra(
            "Lock",
            image: eventHandler.isLocked ? "keyboard.locked" : "keyboard.unlocked",
            isInserted: $showMenuBarExtra
        ) {
            VStack {
                ContentView(eventHandler: eventHandler)
             }
             .frame(minWidth: 300, minHeight: 300)
             .background(Color(.windowBackgroundColor))
             .introspectMenuBarExtraWindow() { window in
                 window.isOpaque = false
                 window.level = .floating
             }
             
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $menuBarViewIsPresented)
        .commands {
            CommandGroup(after: .appInfo) {
                Color.clear
                    .onAppear {
                        eventHandler.isLocked = lockKeyboardOnLaunch
                        eventHandler.selectedLockEffect = selectedLockEffect
                        eventHandler.run()
                        
                        if !isLaunched {
                            isLaunched = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                menuBarViewIsPresented = true
                            }
                        }
                    }
            }
        }

    }
    
    init() {
        let _self = self
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil, queue: .main) { _ in
                debugPrint("------ willTerminateNotification  received------")
                _self.eventHandler.stop()
        }

    }
}

// hide from dock
// https://stackoverflow.com/questions/70697737/hide-app-icon-from-macos-menubar-on-launch
// https://stackoverflow.com/questions/68884499/make-swiftui-app-appear-in-the-macos-dock
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
//        NSApplication.shared.setActivationPolicy(.regular)
//        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        debugPrint("-------- applicationWillTerminate --------")
    }
}
