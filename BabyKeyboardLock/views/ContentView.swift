//
//  ContentView.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
import AppKit



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
    @State private var animationWindow: NSWindow?
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared
    
    @AppStorage("lockKeyboardOnLaunch") private var lockKeyboardOnLaunch: Bool = false
    @AppStorage("selectedLockEffect") var selectedLockEffect: LockEffect = .none
    @AppStorage("selectedTranslationLanguage") var selectedTranslationLanguage: TranslationLanguage = .none
    
    @State var hoveringMoreButton: Bool = false
    var body: some View {
       VStack(alignment: .leading, spacing: 20) {
            HStack{
                Spacer() // push the button to right
                Menu() {
                    Button("About") {
                        AboutView().openInWindow(id: "About", sender: self, focus: true)
                    }
                    
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
                .apply {
                    if #available(macOS 12.0, *) {
                          $0.menuIndicator(.hidden)
                      } else {
                          $0
                      }
                }
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
                .font(.title)
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
            
            if eventHandler.selectedLockEffect == .speakAKeyWord {
                Picker("Translation", selection: $eventHandler.selectedTranslationLanguage) {
                    ForEach(TranslationLanguage.allCases) { language in
                        Text(language.localizedString)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: eventHandler.selectedTranslationLanguage) { newVal in
                    selectedTranslationLanguage = newVal
                }
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
        .frame(width: 300, height: 400)
        .onChange(of: eventHandler.isLocked) { newVal in
            showOrCloseAnimationWindow(isLocked: newVal)
        }.onReceive(eventHandler.$isLocked) { newVal in
            showOrCloseAnimationWindow(isLocked: newVal)
        }.onAppear() {
            debugPrint("onAppear --- ")
            guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == MainWindowID }) else { return}
            
            
        }
    }
    
    private func playLockSound(isLocked: Bool) {
        if isLocked {
            NSSound(named: "light-switch-on")?.play()
        } else {
            guard let nsSound = NSSound(named: "light-switch-off") else { return }
            
            nsSound.play()
        }
    }
    
    private func showOrCloseAnimationWindow(isLocked: Bool) {
        if (!isLocked) {
            NSApp.windows.forEach { window in
                if window.identifier?.rawValue == AnimationWindowID {
                    window.close()
                }
            }
            return
        }
           
        if animationWindow != nil {
            animationWindow?.orderFront(self)
            return
        }
        
        animationWindow = AnimationView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                // Make the window transparent
                guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == AnimationWindowID }) else { return }
                window.isOpaque = false
                // window.backgroundColor = NSColor.clear
                window.level = .floating
                window.titlebarAppearsTransparent = true

                // window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            }
            .openInWindow(id: AnimationWindowID, sender: self)
    }
    
}

#Preview {
    ContentView(eventHandler: EventHandler(isLocked: false))
}
