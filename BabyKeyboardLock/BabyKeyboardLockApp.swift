//
//  BabyKeyboardLockApp.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import SwiftUI
import Combine

let AnimationWindowID = "animationTransparentWindow"
let MainWindowID = "main"

@main
struct BabyKeyboardLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isLaunched: Bool = false

    @AppStorage("lockKeyboardOnLaunch") var lockKeyboardOnLaunch = false
    @AppStorage("selectedLockEffect") var selectedLockEffect: LockEffect = .none
    @AppStorage("selectedTranslationLanguage") var selectedTranslationLanguage: TranslationLanguage = .none
    @ObservedObject var eventHandler: EventHandler = EventHandler.shared

    var body: some Scene {
        Group { }
    }

    init() {
        eventHandler.setLocked(isLocked: lockKeyboardOnLaunch)
        eventHandler.selectedLockEffect = selectedLockEffect
        eventHandler.selectedTranslationLanguage = selectedTranslationLanguage
    }
}

// hide from dock
// https://stackoverflow.com/questions/70697737/hide-app-icon-from-macos-menubar-on-launch
// https://stackoverflow.com/questions/68884499/make-swiftui-app-appear-in-the-macos-dock
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()
    private var cursorOverlayService: CursorOverlayService?
    private var didScheduleStatusItemRefresh = false
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
//        NSApplication.shared.setActivationPolicy(.regular)
//        NSApplication.shared.activate(ignoringOtherApps: true)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let statusButton = statusItem.button {
            updateStatusItemIcon(isLocked: EventHandler.shared.isLocked)
            statusButton.image?.accessibilityDescription = Bundle.applicationName
            statusButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
            statusButton.target = self
            statusButton.action = #selector(handleStatusBarClick)
        }
        scheduleStatusItemRefresh()

        // Add observer for isLocked changes
        EventHandler.shared.$isLocked
            .sink { [weak self] isLocked in
                self?.updateStatusItemIcon(isLocked: isLocked)
            }
            .store(in: &cancellables)

        self.popover = NSPopover()
        // self.popover.contentSize = NSSize(width: 300, height: 400)
        // self.popover.appearance = NSAppearance(named: .accessibilityHighContrastVibrantLight)
        self.popover.behavior = .transient
        let rootView = ContentView(eventHandler: EventHandler.shared)
        let nSHostingController = NSHostingController(rootView: rootView)

        // nSHostingController.preferredContentSize = NSSize(width: 300, height: 300)

        self.popover.contentViewController = nSHostingController
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.showPopover()
            EventHandler.shared.run()
        }

        // Initialize cursor overlay service for mouse lock indicator
        cursorOverlayService = CursorOverlayService.shared
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        EventHandler.shared.stop()
        debugLog("-------- applicationWillTerminate --------")
    }

    private func updateStatusItemIcon(isLocked: Bool) {
        guard let statusButton = statusItem.button else { return }
        let imageName = isLocked ? "keyboard.locked" : "keyboard.unlocked"

        let image = NSImage(named: imageName)
            ?? NSImage(systemSymbolName: imageName, accessibilityDescription: Bundle.applicationName)

        if let image {
            image.isTemplate = true
            statusButton.image = image
            statusButton.imageScaling = .scaleProportionallyDown
            statusItem.length = NSStatusItem.squareLength
            statusButton.title = ""
        } else {
            // Fallback to keep the status item visible if the image fails to load.
            statusButton.title = "BK"
            statusItem.length = NSStatusItem.variableLength
        }
    }

    private func scheduleStatusItemRefresh() {
        guard !didScheduleStatusItemRefresh else { return }
        didScheduleStatusItemRefresh = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.didScheduleStatusItemRefresh = false
            self.updateStatusItemIcon(isLocked: EventHandler.shared.isLocked)
        }
    }

    func showPopover(){
        if let button = statusItem.button {
            // Get the actual menu bar height
            let menuBarHeight = NSStatusBar.system.thickness

            // Create properly adjusted bounds
            var adjustedBounds = button.bounds
            adjustedBounds.origin.y -= menuBarHeight * 0.1
            popover.show(relativeTo: adjustedBounds, of: button, preferredEdge: .minY)

            // Make the popover's window active
            if let window = popover.contentViewController?.view.window {
                window.makeKey()
            }
        }
    }

    func hidePopover() {
        if popover.isShown {
            self.popover.performClose(nil)
        }
    }

    @objc func handleStatusBarClick(_ sender: NSStatusBarButton? = nil) {
        guard let event = NSApp.currentEvent else {
            debugLog("No current event")
            return
        }

        debugLog("Event type: \(event.type.rawValue)")

        switch event.type {
        case .leftMouseUp:
            EventHandler.shared.setLocked(isLocked: !EventHandler.shared.isLocked)
        case .rightMouseUp:
            if popover.isShown {
                hidePopover()
            } else {
                showPopover()
            }
        default:
            debugLog("Unhandled event type: \(event.type.rawValue)")
            return
        }
    }
}
