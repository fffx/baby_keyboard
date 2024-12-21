//
//  ContentView.swift
//  baby_keyboard
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
import AppKit

struct LockSwitcher: View {
    @Binding var isLocked: Bool
    @State private var isHovering = false // Track hover state
    var label: String
    var body: some View {
        Button(action: {
            withAnimation {
                isLocked.toggle()
            }
        }) {
            HStack(spacing: 8) { // Keep the HStack
                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(isLocked ? .blue : .gray)
                
                Text(isLocked ? "Locked" : "Unlocked")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(6) // Add padding to the HStack itself
            .background( // Add background for hover effect
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(isHovering ? 0.1 : 0)) // Subtle background on hover
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(isHovering ? 0.3 : 0), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle()) // Very important!
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

class WindowManager: NSObject, ObservableObject {
    var window: NSWindow?
    
    func configureWindow(for window: NSWindow, isLocked: Bool) { // Add isLocked parameter
        self.window = window
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        // window.title = "Lock Control"
        window.level = .floating
        // window.level = isLocked ? .floating : .normal // Set window level based on lock state
    }
}

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @StateObject var windowManager = WindowManager()
    @EnvironmentObject var eventHandler: EventHandler
    var body: some View {
        VStack {
            LockSwitcher(isLocked: $eventHandler.isLocked, label: "Lock/Unlock Keyboard")
        }
        .padding()
        .onChange(of: eventHandler.isLocked){ _, newVal in
            if newVal{
                openWindow(id: FireworkWindowID)
            } else {
                NSApp.windows.first(where: { $0.identifier?.rawValue == FireworkWindowID })?.close()
            }
        }
        .onAppear {
            // Open the other windows here if needed
            if eventHandler.isLocked {
                openWindow(id: FireworkWindowID)
            }
        }
    }
}

#Preview {
    ContentView()
}
