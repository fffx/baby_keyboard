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
    @State private var isLaunched: Bool = false
    @State var menuBarViewIsPresented: Bool = false
    
    @AppStorage("lockKeyboardOnLaunch") var lockKeyboardOnLaunch = false
    @AppStorage("selectedLockEffect") var selectedLockEffect: LockEffect = .none
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @ObservedObject var eventHandler = EventHandler()
    
    @State var mainWindow: NSWindow? = nil
    // var letterView: LetterView!
    var body: some Scene {
        Window("Firework window", id: FireworkWindowID) {
            FireworkView().frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .environmentObject(eventHandler)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        MenuBarExtra(
            "BabyKeyboardLock",
            systemImage: eventHandler.isLocked ? "lock.fill" : "lock.open.fill",
            isInserted: $showMenuBarExtra
        ) {
            VStack {
                ContentView()
                .environmentObject(eventHandler)
             }
             .frame(width: 300, height: 300)
             .background(.windowBackground)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $menuBarViewIsPresented)
        .onChange(of: scenePhase, initial: true) { _, newValue in
            debugPrint("scenePhase: \(newValue)")
            switch newValue {
            case .active:
                if !isLaunched {
                    isLaunched = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        menuBarViewIsPresented = true
                    }
                }
            default: break
            }
        }
        
    }
    
    init() {
        eventHandler.isLocked = lockKeyboardOnLaunch
        eventHandler.selectedLockEffect = selectedLockEffect
        eventHandler.run()
        
        let _self = self
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil, queue: .main) { _ in
                debugPrint("------ willTerminateNotification  received------")
                _self.eventHandler.stop()
        }

    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        debugPrint("-------- applicationWillTerminate --------")
    }
}
