//
//  HotCornerService.swift
//  BabyKeyboardLock
//
//  Created on 04.11.2025.
//

import Foundation
import CoreGraphics
import AppKit

class HotCornerService {
    private var eventMonitor: Any?
    private var isEnabled: Bool = false
    private let cornerSize: CGFloat = 5.0 // Size of the hot corner activation zone
    private var onCornerTriggered: (() -> Void)?
    
    // Track previous position to detect when entering corner
    private var wasInCorner: Bool = false
    private var lastTriggerTime: Date = .distantPast
    private let triggerCooldown: TimeInterval = 1.0 // Minimum time between triggers
    
    init() {}
    
    func start(onCornerTriggered: @escaping () -> Void) {
        guard eventMonitor == nil else { return }
        
        self.onCornerTriggered = onCornerTriggered
        self.isEnabled = true
        
        // Monitor mouse moved events globally
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMove(event: event)
        }
        
        debugLog("HotCornerService started")
    }
    
    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        isEnabled = false
        wasInCorner = false
        lastTriggerTime = .distantPast
        debugLog("HotCornerService stopped")
    }
    
    private func handleMouseMove(event: NSEvent) {
        guard isEnabled else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        
        // Get the screen that contains the mouse
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) else {
            return
        }
        
        let screenFrame = screen.frame
        
        // Calculate top-right corner bounds
        // Note: In macOS coordinates, y=0 is at the bottom
        let topRightCorner = NSRect(
            x: screenFrame.maxX - cornerSize,
            y: screenFrame.maxY - cornerSize,
            width: cornerSize,
            height: cornerSize
        )
        let isInCorner = NSMouseInRect(mouseLocation, topRightCorner, false)
        
        // Trigger only when entering the corner (transition from false to true)
        // and cooldown period has passed
        if isInCorner && !wasInCorner {
            let now = Date()
            let timeSinceLastTrigger = now.timeIntervalSince(lastTriggerTime)
            
            if timeSinceLastTrigger >= triggerCooldown {
                debugLog("Hot corner triggered at position: \(mouseLocation)")
                lastTriggerTime = now
                
                // Trigger action asynchronously to avoid blocking mouse events
                if let callback = onCornerTriggered {
                    DispatchQueue.global(qos: .userInteractive).async {
                        callback()
                    }
                }
            }
        }
        
        wasInCorner = isInCorner
    }
    
    deinit {
        stop()
    }
}
