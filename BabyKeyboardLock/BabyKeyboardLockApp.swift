//
//  BabyKeyboardLockApp.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
let FireworkWindowID = "fireworkTransparentWindow"

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        for window in NSApplication.shared.windows {
            window.close()
        }
        NSApplication.shared.terminate(self)
    }
}

@main
struct BabyKeyboardLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var eventHandler = EventHandler()
    // var letterView: LetterView!
    var body: some Scene {
        Window("Baby Keyboard Lock", id: "main") {
            ContentView()
        }
        .environmentObject(eventHandler)
        //.windowStyle(.hiddenTitleBar)
        // .windowResizability(.contentSize)
        
        Window("Firework window", id: FireworkWindowID) {
            FireworkView().frame(maxWidth: .infinity, maxHeight: .infinity)
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                // .disabled(true)
                .onAppear {
                    // Make the window transparen
                    guard let window =  NSApp.windows.first(where: { $0.identifier?.rawValue == FireworkWindowID }) else { return }
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
        eventHandler.run()
        // Show the firework window
        // fireworkController.showWindow(nil)
        
        // Configure your main window if needed
        //if let window = NSApp.windows.first {
        // Your main window configuration here
        //}
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
