//
//  ViewExtenstion.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 4.1.2025.
//
import SwiftUI

extension View {
    @discardableResult
    func openInWindow(title: String = "", id: String, sender: Any? = nil, focus: Bool = false) -> NSWindow {
        debugPrint("openInWindow ----- \(id)")
        NSApp.windows.forEach { window in
            if window.identifier?.rawValue == id { window.close() }
        }
        
        let controller = NSHostingController(rootView: self)
        let win = NSWindow(contentViewController: controller)
        win.contentViewController = controller
        win.title = title
        win.identifier = NSUserInterfaceItemIdentifier(id)
        
    
        if sender != nil {
            win.orderFront(sender)
            if focus {
                debugPrint("openInWindow ----- \(id) focus")
                win.makeKeyAndOrderFront(sender)
            }
        }

        return win
    }
}

extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}
