//
//  ContentView.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
import AppKit

struct PinWindow: ViewModifier {
    let isPinned: Bool
    
    func body(content: Content) -> some View {
        content
            .background(PinWindowBackground(isPinned: isPinned))
    }
}

private struct PinWindowBackground: NSViewRepresentable {
    let isPinned: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            updateWindowLevel(window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            updateWindowLevel(window)
        }
    }
    
    private func updateWindowLevel(_ window: NSWindow) {
        window.level = isPinned ? .floating : .normal
    }
}

extension View {
    func pinWindow(isPinned: Bool) -> some View {
        modifier(PinWindow(isPinned: isPinned))
    }
}

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var eventHandler: EventHandler
    var body: some View {
        HStack(spacing: 0) {
            Button("x", action: {
                let app = NSApplication.shared
                let window = app.windows.first { $0.identifier?.rawValue == "main" }
                window?.performClose(nil)
                eventHandler.stop()
            })
            .offset(y: -15)
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
            .frame(alignment: .topLeading)
            
            Spacer()
            // ...existing code...
        }
        //.border(Color.red)
        VStack {
            // LockSwitcher(isLocked: $eventHandler.isLocked, label: "Lock/Unlock Keyboard")
            Toggle("Lock Keyboard", isOn: $eventHandler.isLocked)
                .toggleStyle(SwitchToggleStyle(tint: .red))
                .scaledToFill()
                .disabled(!eventHandler.accessibilityPermissionGranted)
            Text("Please grant accessibility permissions in System Settings > Secuerity & Privacy > Accessibility")
                .opacity(eventHandler.accessibilityPermissionGranted ? 0 : 1)
                .padding()
                .font(.callout)
                .bold()
            
        }
        .padding()
        // .border(Color.red)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pinWindow(isPinned: eventHandler.isLocked)
        .onChange(of: eventHandler.isLocked){ _, newVal in
            if newVal{
                openWindow(id: FireworkWindowID)
            } else {
                NSApp.windows.first(where: { $0.identifier?.rawValue == FireworkWindowID })?.close()
            }
        }
        .onAppear {
            debugPrint("appeared ------------ ")
            // Open the other windows here if needed
            if eventHandler.isLocked {
                openWindow(id: FireworkWindowID)
            }
            
            let app = NSApplication.shared
            let mainWindow = app.windows.first { $0.identifier?.rawValue == "main" }
            mainWindow?.standardWindowButton(.closeButton)?.isHidden = true
            mainWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
            mainWindow?.standardWindowButton(.zoomButton)?.isHidden = true

        }
    }
}

#Preview {
    ContentView()
        .environmentObject(EventHandler(isLocked: false))
}
