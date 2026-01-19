//
//  CursorOverlayService.swift
//  BabyKeyboardLock
//
//  Created by Fangxing Xiong on 19.01.2026.
//

import AppKit
import SwiftUI
import Combine

/// Service that shows the app icon near the cursor when mouse is locked via hot corner
class CursorOverlayService: ObservableObject {
    static let shared = CursorOverlayService()

    private var overlayWindow: NSWindow?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    private let iconSize: CGFloat = 24
    private let offsetX: CGFloat = 16  // Offset from cursor
    private let offsetY: CGFloat = 16

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        // Observe changes to lockedViaHotCorner state
        EventHandler.shared.$isLocked
            .combineLatest(EventHandler.shared.$lockedViaHotCorner)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLocked, viaHotCorner in
                if isLocked && viaHotCorner {
                    self?.showOverlay()
                } else {
                    self?.hideOverlay()
                }
            }
            .store(in: &cancellables)
    }

    func showOverlay() {
        guard overlayWindow == nil else {
            startMouseTracking()
            return
        }

        // Create the overlay window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: iconSize + 8, height: iconSize + 8),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .screenSaver + 1  // Above everything
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Create the icon view
        let hostingView = NSHostingView(rootView: CursorOverlayView())
        window.contentView = hostingView

        overlayWindow = window
        window.orderFront(nil)

        // Start tracking mouse movement
        startMouseTracking()

        // Initial position
        updatePosition()
    }

    func hideOverlay() {
        stopMouseTracking()
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }

    private func startMouseTracking() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.updatePosition()
        }
    }

    private func stopMouseTracking() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func updatePosition() {
        guard let window = overlayWindow else { return }

        let mouseLocation = NSEvent.mouseLocation

        // Position the window near the cursor (bottom-right of cursor)
        let newOrigin = NSPoint(
            x: mouseLocation.x + offsetX,
            y: mouseLocation.y - offsetY - iconSize
        )

        // Ensure the window stays on screen
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
            var adjustedOrigin = newOrigin

            // Keep within screen bounds
            let windowSize = window.frame.size
            let screenFrame = screen.frame

            if adjustedOrigin.x + windowSize.width > screenFrame.maxX {
                adjustedOrigin.x = mouseLocation.x - offsetX - windowSize.width
            }
            if adjustedOrigin.y < screenFrame.minY {
                adjustedOrigin.y = mouseLocation.y + offsetY
            }

            window.setFrameOrigin(adjustedOrigin)
        } else {
            window.setFrameOrigin(newOrigin)
        }
    }

    deinit {
        hideOverlay()
        cancellables.removeAll()
    }
}

/// SwiftUI view for the cursor overlay icon
struct CursorOverlayView: View {
    var body: some View {
        ZStack {
            // Semi-transparent background circle
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 32, height: 32)

            // Use the same icon as the toolbar
            Image("keyboard.locked")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundColor(.white)
        }
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}
