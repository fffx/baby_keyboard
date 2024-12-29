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

struct HoverableMenuStyle: MenuStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.gray.opacity(0.2) : Color.clear)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}



struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var eventHandler: EventHandler
    
    @AppStorage("lockKeyboardOnLaunch") private var lockKeyboardOnLaunch: Bool = false
    @AppStorage("selectedLockEffect") var selectedLockEffect: LockEffect = .none

    @State var hoveringMoreButton: Bool = false
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 20) {
                HStack{
                    Spacer() // push the button to right
                    Menu {
                        Button("Quit \(Bundle.applicationName)") {
                              NSApp.terminate(nil)
                          }
                    } label: {
                        Label("", systemImage: "ellipsis").font(.callout)
                            .onHover { _ in
                                // TODO
                            }
                    }
                    .menuStyle(HoverableMenuStyle())
                    .menuStyle(BorderlessButtonMenuStyle())
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .onHover { _ in
                        hoveringMoreButton = true
                    }
                }
                
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
                .onChange(of: eventHandler.isLocked) { newVal in
                    playLockSound(isLocked: newVal)
                }.onAppear(){
                    if eventHandler.isLocked {
                        playLockSound(isLocked: true)
                    }
                }
                    
                if !eventHandler.accessibilityPermissionGranted {
                    Text("accessibility_permission_grant_hint \(Bundle.applicationName)")
                        .opacity(eventHandler.accessibilityPermissionGranted ? 0 : 1)
                        .font(.callout)
                        .bold()
                        .fixedSize(horizontal: false, vertical: true)
                }
                Picker("Effect", selection: $eventHandler.selectedLockEffect) {
                    ForEach(LockEffect.allCases) { effect in
                        Text(effect.localizedString)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: eventHandler.selectedLockEffect) { newVal in
                    selectedLockEffect = newVal
                }
                
                
                Toggle(isOn: $lockKeyboardOnLaunch) {
                    Text("Lock keyboard on launch")
                }
                .toggleStyle(CheckboxToggleStyle())
                // .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                Text("unlock_shortcut_hint")
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
//            .border(Color.red)
//            .background(Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // .pinWindow(isPinned: eventHandler.isLocked)
            .onChange(of: eventHandler.isLocked){ newVal in
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
    
    private func playLockSound(isLocked: Bool) {
        if isLocked {
            NSSound(named: "light-switch-on")?.play()
        } else {
            guard let nsSound = NSSound(named: "light-switch-off") else { return }
            
            nsSound.play()
        }
    }

}

#Preview {
    ContentView(eventHandler: EventHandler(isLocked: false))
}
