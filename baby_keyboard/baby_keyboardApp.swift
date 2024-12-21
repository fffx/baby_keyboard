//
//  baby_keyboardApp.swift
//  baby_keyboard
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
struct baby_keyboardApp: App {
    @ObservedObject var eventHandler = EventHandler()
    // var letterView: LetterView!
    var body: some Scene {
        Window("Main Window", id: "main") {
            ContentView()
        }
        .environmentObject(eventHandler)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        Window("Firework window", id: FireworkWindowID) {
            FireworkView().frame(maxWidth: .infinity, maxHeight: .infinity)
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                // .disabled(true)
                .onAppear {
                    // Make the window transparen
                    guard let window =  NSApp.windows.first(where: { $0.identifier?.rawValue == FireworkWindowID }) else { return }
                    print(window.identifier!.rawValue)
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

