//
//  ViewExtenstion.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 4.1.2025.
//
import SwiftUI

extension View {
    @discardableResult
    func openInWindow(title: String = "", id: String, sender: Any? = nil) -> NSWindow {
        debugPrint("openInWindow ----- \(id)")
        let controller = NSHostingController(rootView: self)
        let win = NSWindow(contentViewController: controller)
        win.contentViewController = controller
        win.title = title
        win.identifier = NSUserInterfaceItemIdentifier(id)
        if sender != nil {
            // win.makeKeyAndOrderFront(sender)
            win.orderFront(sender)
        }

        return win
    }
}

extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}
