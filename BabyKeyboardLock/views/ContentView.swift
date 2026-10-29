//
//  ContentView.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 19.10.2024.
//

import SwiftUI
import AppKit

struct HoverableMenuStyle: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
    }
}

extension View {
    @ViewBuilder
    func apply<T: View>(_ modifier: (Self) -> T) -> some View {
        modifier(self)
    }
}

struct ContentView: View {
    @State private var animationWindow: NSWindow?
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared
    @ObservedObject var deviceManager: InputDeviceManager = InputDeviceManager.shared

    @AppStorage("lockKeyboardOnLaunch") private var lockKeyboardOnLaunch: Bool = false
    @State private var launchAtLogin = false
    @State private var showingMouseLockAlert = false

    @State var hoveringMoreButton: Bool = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
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
                .padding(.bottom, eventHandler.accessibilityPermissionGranted ? 10 : 5)
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Input Devices to Block")
                        .font(.headline)

                    if deviceManager.devices.isEmpty {
                        Text("No input devices detected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(deviceManager.devices) { device in
                                Toggle(isOn: Binding(
                                    get: { device.isBlocked },
                                    set: { newValue in
                                        if newValue && device.type == .mouseOrTrackpad {
                                            showingMouseLockAlert = true
                                        }
                                        deviceManager.setDeviceBlocked(id: device.id, isBlocked: newValue)
                                    }
                                )) {
                                    HStack(spacing: 8) {
                                        Image(systemName: device.type.systemImage)
                                            .frame(width: 16)
                                        Text(device.name)
                                            .lineLimit(1)
                                        Spacer()
                                        if let transport = device.transport, !transport.isEmpty {
                                            Text(transport)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .toggleStyle(CheckboxToggleStyle())
                            }
                        }

                        if deviceManager.isAnyMouseBlocked {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(.secondary)
                                Text("mouse_locked_shortcut_hint")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                .padding(.vertical, 2)

                Divider()

                Picker("Effect", selection: $eventHandler.selectedLockEffect) {
                    ForEach(LockEffect.allCases) { effect in
                        Text(effect.localizedString)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: eventHandler.selectedLockEffect) { newVal in
                    UserDefaults.standard.set(newVal.rawValue, forKey: "selectedLockEffect")
                    // Update animation window when effect changes
                    showOrCloseAnimationWindow(isLocked: eventHandler.isLocked)
                }

                if eventHandler.selectedLockEffect == .speakAKeyWord {
                    Picker("Translation", selection: $eventHandler.selectedTranslationLanguage) {
                        ForEach(TranslationLanguage.allCases) { language in
                            Text(language.localizedString)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: eventHandler.selectedTranslationLanguage) { newVal in
                        UserDefaults.standard.set(newVal.rawValue, forKey: "selectedTranslationLanguage")
                    }
                }

                Toggle(isOn: $lockKeyboardOnLaunch) {
                    Text("Lock keyboard on launch")
                }
                .toggleStyle(CheckboxToggleStyle())

                Toggle(isOn: $launchAtLogin) {
                    Text("Launch on startup")
                }
                .toggleStyle(CheckboxToggleStyle())
                .disabled(!LaunchAtLoginService.isSupported)
                .onChange(of: launchAtLogin) { newValue in
                    let isEnabled = LaunchAtLoginService.setEnabled(newValue)
                    if isEnabled != newValue {
                        launchAtLogin = isEnabled
                    }
                }

                Toggle(isOn: $eventHandler.hotCornerEnabled) {
                    Text("Lock with top-right hotcorner")
                }
                .toggleStyle(CheckboxToggleStyle())

                Text("When locked with hot corner, mouse clicks are locked as well")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, -10)

                Spacer(minLength: 10)

                Text("unlock_shortcut_hint")
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .frame(width: 320, height: 480)
        .alert(
            "mouse_lock_alert_title",
            isPresented: $showingMouseLockAlert
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("mouse_lock_alert_message")
        }
        .onChange(of: eventHandler.isLocked) { newVal in
            showOrCloseAnimationWindow(isLocked: newVal)
        }.onReceive(eventHandler.$isLocked) { newVal in
            showOrCloseAnimationWindow(isLocked: newVal)
        }.onAppear() {
            launchAtLogin = LaunchAtLoginService.isEnabled
            debugLog("onAppear --- ")
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
        // Only show animation window for effects that need visual animations
        let needsAnimationWindow = eventHandler.selectedLockEffect == .confettiConnon

        if (!isLocked || !needsAnimationWindow) {
            NSApp.windows.forEach { window in
                if window.identifier?.rawValue == AnimationWindowID {
                    window.close()
                }
            }
            animationWindow = nil
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
                window.backgroundColor = NSColor.clear
                window.level = .floating

                // Completely hide the title bar
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.borderless)
                window.styleMask.remove(.titled)

                window.hasShadow = false // Disable shadow to prevent lagging

                // Enable layer backing for smooth animations
                if let contentView = window.contentView {
                    contentView.wantsLayer = true
                    contentView.layer?.backgroundColor = NSColor.clear.cgColor
                }
            }
            .openInWindow(id: AnimationWindowID, sender: self)
    }
}

#Preview {
    ContentView(eventHandler: EventHandler(isLocked: false))
}
