//
//  baby_keyboardApp.swift
//  baby_keyboard
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI

@main
struct baby_keyboardApp: App {
    private let fireworkWindowID = "fireworkTransparentWindow"
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var eventHandler = EventHandler()
    // var letterView: LetterView!
    
    
    var body: some Scene {
        Window("Main Window", id: "main") {
            ContentView()
                .onAppear {
                    // Open the other windows here if needed
                    if eventHandler.isLocked {
                        openWindow(id: fireworkWindowID)
                    }
                }   
        }
        .environmentObject(eventHandler)
        .windowStyle(.hiddenTitleBar)
        
        Window("Firework window", id: fireworkWindowID) {
            FireworkView().frame(maxWidth: .infinity, maxHeight: .infinity)
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                // .disabled(true)
                .onAppear {
                    // Make the window transparen
                    guard let window =  NSApp.windows.first(where: { $0.identifier?.rawValue == fireworkWindowID }) else { return }
                    print(window.identifier!.rawValue)
                    window.isOpaque = false
                    // window.backgroundColor = NSColor.clear
                    window.level = .floating
                
                    // window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                }
        }
        .environmentObject(eventHandler)
        
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

