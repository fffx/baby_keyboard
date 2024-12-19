//
//  baby_keyboardApp.swift
//  baby_keyboard
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI

@main
struct baby_keyboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    var debug = true
    var timer = 100
    init() {
        // todo request accessiblity permission
        let eventHandler = EventHandler(debug: debug)
        eventHandler.scheduleTimer(duration: timer)
        eventHandler.run()
    }
}

