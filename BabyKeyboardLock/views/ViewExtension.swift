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
        debugLog("openInWindow ----- \(id)")
        NSApp.windows.forEach { window in
            if window.identifier?.rawValue == id { window.close() }
        }

        let controller = NSHostingController(rootView: self)
        let win = NSWindow(contentViewController: controller)
        win.contentViewController = controller
        win.title = title
        win.identifier = NSUserInterfaceItemIdentifier(id)


        if sender != nil {
            if focus {
                debugLog("openInWindow ----- \(id) focus")
                NSApp.activate(ignoringOtherApps: true)
                win.makeKeyAndOrderFront(sender)
            } else {
                win.orderFront(sender)
            }
        }

        return win
    }
}

extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}
