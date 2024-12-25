//
//  BabyKeyboardLockApp.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
let FireworkWindowID = "fireworkTransparentWindow"
let MainWindowID = "main"

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        for window in NSApplication.shared.windows {
            window.close()
        }
        NSApplication.shared.terminate(self)
    }
}

// https://stackoverflow.com/a/77297913/5615038
//extension Task where Success == Void, Failure == Never {
//    static func waitTillCancel() async {
//        let asyncStream = AsyncStream<Int> { _ in }
//        for await _ in asyncStream { }
//    }
//}

@main
struct BabyKeyboardLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("lockKeyboardOnLaunch") var lockKeyboardOnLaunch = false
    @AppStorage("selectedLockEffect") var selectedLockEffect: LockEffect = .none
    @ObservedObject var eventHandler = EventHandler()
    
    @State var mainWindow: NSWindow? = nil
    // var letterView: LetterView!
    var body: some Scene {
        Window("BabyKeyboardLock", id: MainWindowID) {
            ContentView()
//            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeMainNotification), perform: { newValue in
//                debugPrint("Focused = true", newValue.hashValue)
//                mainWindow?.animator().alphaValue = 1
//            })
//            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification), perform: { newValue in
//                debugPrint("Focused = false", newValue.hashValue)
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    mainWindow?.animator().alphaValue = 0.7 // Adjust opacity as needed
//                }
//            }).onAppear(){
//                mainWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == MainWindowID })
//            }
        }
        .environmentObject(eventHandler)
        .windowStyle(.hiddenTitleBar)
        // .windowResizability(.contentSize)
    
        
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
        return true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        debugPrint("-------- applicationWillTerminate --------")
    }
}
