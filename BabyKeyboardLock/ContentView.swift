//
//  ContentView.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
import AppKit
extension Bundle {
    class var applicationName: String {

        if let displayName: String = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return displayName
        } else if let name: String = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            return name
        }
        return "App Name"
    }
}
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
    @AppStorage("lockKeyboardOnLaunch") private var lockKeyboardOnLaunch: Bool = false
    @AppStorage("selectedLockEffect") var selectedLockEffect: LockEffect = .none

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 20) {
                // LockSwitcher(isLocked: $eventHandler.isLocked, label: "Lock/Unlock Keyboard")
                Toggle(isOn: $eventHandler.isLocked)
                {
                    Label(
                        "Lock Keyboard",
                        image: eventHandler.isLocked ? "keyboard.locked" : "keyboard.unlocked"
                    )
                    .bold().font(.title)
                    .foregroundColor(eventHandler.accessibilityPermissionGranted ? .primary : .gray)
                }
                .toggleStyle(SwitchToggleStyle(tint: .red))
                .scaledToFill()
                .disabled(!eventHandler.accessibilityPermissionGranted)
                .padding(.bottom, eventHandler.accessibilityPermissionGranted ? 20 : 5)
                .padding(.top, 15)
                .onChange(of: eventHandler.isLocked) { _, newVal in
                    if newVal {
                        NSSound(named: "Glass")?.play()
                    } else {
                        NSSound(named: "Bottle")?.play()
                    }
                }.onAppear(){
                    if eventHandler.isLocked {
                        NSSound(named: "Glass")?.play()
                    }
                }
                    
                if !eventHandler.accessibilityPermissionGranted {
                    Text("""
                         Please grant accessibility permissions to [\(Bundle.applicationName)] in:
                         [System Settings]
                             > [Secuerity & Privacy] 
                                 > [Accessibility] (scroll down)
                         """)
                        .opacity(eventHandler.accessibilityPermissionGranted ? 0 : 1)
                        .font(.callout)
                        .bold()
                        .fixedSize(horizontal: false, vertical: true)
                }
                Picker("Effect", selection: $eventHandler.selectedLockEffect) {
                    ForEach(LockEffect.allCases) { effect in
                        Text(effect.rawValue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: eventHandler.selectedLockEffect) { _, newVal in
                    selectedLockEffect = newVal
                }
                
                
                Toggle(isOn: $lockKeyboardOnLaunch) {
                    Text("Lock keyboard on launch")
                }
                .toggleStyle(CheckboxToggleStyle())
                // .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                Text("You can use shortcut Ctrl + Option + U to toggle keyboard lock")
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
//            .border(Color.red)
//            .background(Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // .pinWindow(isPinned: eventHandler.isLocked)
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
                
//                let app = NSApplication.shared
//                let mainWindow = app.windows.first { $0.identifier?.rawValue == "main" }
//                mainWindow?.standardWindowButton(.closeButton)?.isHidden = true
//                mainWindow?.standardWindowButton(.miniaturizeButton)?.isHidden = true
//                mainWindow?.standardWindowButton(.zoomButton)?.isHidden = true
                
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    ContentView()
        .environmentObject(EventHandler(isLocked: false))
}
