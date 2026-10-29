//
//  BabyKeyboardLockAppTests.swift
//  BabyKeyboardLockTests
//
//  Created by Fangxing Xiong on 28.10.2024.
//

import Testing
import SwiftUI
import AppKit
@testable import BabyKeyboardLock

@Suite(.serialized)
struct BabyKeyboardLockAppTests {

    @MainActor
    @Test func testAppDelegateInitialization() async throws {
        let delegate = AppDelegate()

        // Verify delegate is properly initialized
        #expect(delegate.statusItem == nil, "Status item should be nil before applicationDidFinishLaunching")
    }

    @MainActor
    @Test func testStatusItemCreation() async throws {
        let delegate = AppDelegate()

        // Simulate app launch
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        delegate.applicationDidFinishLaunching(notification)

        // Give async operations time to complete
        try await Task.sleep(for: .milliseconds(100))

        // Verify status item was created
        #expect(delegate.statusItem != nil, "Status item should be created after launch")
    }

    @MainActor
    @Test func testStatusBarIconReflectsLockState() async throws {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)

        // Set initial state
        EventHandler.shared.isLocked = true
        delegate.applicationDidFinishLaunching(notification)

        try await Task.sleep(for: .milliseconds(100))

        if let button = delegate.statusItem?.button {
            #expect(button.image?.name() == "keyboard.locked", "Icon should show locked state")
        }

        // Change lock state
        EventHandler.shared.isLocked = false

        // Give Combine publisher time to propagate
        try await Task.sleep(for: .milliseconds(100))

        if let button = delegate.statusItem?.button {
            #expect(button.image?.name() == "keyboard.unlocked", "Icon should show unlocked state")
        }
    }

    @MainActor
    @Test func testApplicationShouldNotTerminateAfterLastWindowClosed() async throws {
        let delegate = AppDelegate()
        let app = NSApplication.shared

        let shouldTerminate = delegate.applicationShouldTerminateAfterLastWindowClosed(app)

        #expect(!shouldTerminate, "App should stay running when last window closes")
    }

    @MainActor
    @Test func testPopoverShowAndHide() async throws {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        delegate.applicationDidFinishLaunching(notification)

        // Wait for initialization
        try await Task.sleep(for: .milliseconds(600))

        // Test hide popover
        delegate.hidePopover()

        // Give time for animation
        try await Task.sleep(for: .milliseconds(100))

        // Popover should be closed after hide
        // Note: We can't reliably test isShown in unit tests without full UI
    }

    @MainActor
    @Test func testPopoverEventMonitorLifecycle() async throws {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        delegate.applicationDidFinishLaunching(notification)

        // Wait for initialization and initial popover presentation (scheduled after 500ms)
        try await Task.sleep(for: .milliseconds(600))

        // Hiding the popover must remove the outside-click monitor
        delegate.hidePopover()
        #expect(delegate.eventMonitor == nil, "Event monitor should be nil after popover is hidden")

        // Showing the popover and then closing it via hidePopover or delegate callback clears monitor
        delegate.showPopover()
        delegate.hidePopover()
        #expect(delegate.eventMonitor == nil, "Event monitor should be nil after hiding popover")
    }

    @Test func testWindowConstants() async throws {
        #expect(AnimationWindowID == "animationTransparentWindow", "Animation window ID should match")
        #expect(MainWindowID == "main", "Main window ID should match")
    }

    @MainActor
    @Test func testAnimateStatusItemOnKeyPressWhenLocked() async throws {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)

        EventHandler.shared.isLocked = true
        delegate.applicationDidFinishLaunching(notification)
        try await Task.sleep(for: .milliseconds(100))

        guard let button = delegate.statusItem?.button,
              let layer = button.layer else {
            Issue.record("Button or layer should not be nil")
            return
        }

        delegate.animateStatusItemOnKeyPress(isAutorepeat: false)
        #expect(layer.animation(forKey: "keyPressShakeAnimation") != nil, "Shake animation should be attached to layer")
    }

    @MainActor
    @Test func testAnimateStatusItemOnKeyPressWhenUnlocked() async throws {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)

        EventHandler.shared.isLocked = false
        delegate.applicationDidFinishLaunching(notification)
        try await Task.sleep(for: .milliseconds(100))

        guard let button = delegate.statusItem?.button,
              let layer = button.layer else {
            Issue.record("Button or layer should not be nil")
            return
        }

        delegate.animateStatusItemOnKeyPress(isAutorepeat: false)
        #expect(layer.animation(forKey: "keyPressShakeAnimation") == nil, "Shake animation should not run when unlocked")
    }

    @MainActor
    @Test func testAutorepeatDoesNotInterruptExistingAnimation() async throws {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)

        EventHandler.shared.isLocked = true
        delegate.applicationDidFinishLaunching(notification)
        try await Task.sleep(for: .milliseconds(100))

        guard let button = delegate.statusItem?.button,
              let layer = button.layer else {
            Issue.record("Button or layer should not be nil")
            return
        }

        delegate.animateStatusItemOnKeyPress(isAutorepeat: false)
        let initialAnimation = layer.animation(forKey: "keyPressShakeAnimation")
        #expect(initialAnimation != nil)

        // An autorepeat should not replace the existing running animation
        delegate.animateStatusItemOnKeyPress(isAutorepeat: true)
        let currentAnimation = layer.animation(forKey: "keyPressShakeAnimation")
        #expect(currentAnimation === initialAnimation, "Autorepeat should keep existing animation playing")
    }

    @MainActor
    @Test func testUnlockingClearsRunningAnimation() async throws {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)

        EventHandler.shared.isLocked = true
        delegate.applicationDidFinishLaunching(notification)
        try await Task.sleep(for: .milliseconds(100))

        guard let button = delegate.statusItem?.button,
              let layer = button.layer else {
            Issue.record("Button or layer should not be nil")
            return
        }

        delegate.animateStatusItemOnKeyPress(isAutorepeat: false)
        #expect(layer.animation(forKey: "keyPressShakeAnimation") != nil)

        // Unlocking the keyboard should remove the running animation
        EventHandler.shared.isLocked = false
        try await Task.sleep(for: .milliseconds(100))

        #expect(layer.animation(forKey: "keyPressShakeAnimation") == nil, "Animation should be removed when unlocked")
    }

    @MainActor
    @Test func testShakeIntensityAndDurationScalesWithPressSpeed() async throws {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)

        EventHandler.shared.isLocked = true
        delegate.applicationDidFinishLaunching(notification)
        try await Task.sleep(for: .milliseconds(100))

        guard let button = delegate.statusItem?.button,
              let layer = button.layer else {
            Issue.record("Button or layer should not be nil")
            return
        }

        // Test math helpers
        #expect(delegate.shakeIntensity(pressCount: 1) == 1.0)
        #expect(delegate.shakeIntensity(pressCount: 6) >= 2.5)
        #expect(delegate.shakeDuration(pressCount: 1) == 0.25)
        #expect(delegate.shakeDuration(pressCount: 6) < 0.20)

        // Single press -> base shake amplitude
        delegate.resetKeyPressHistory()
        delegate.animateStatusItemOnKeyPress(isAutorepeat: false)
        guard let singleAnim = layer.animation(forKey: "keyPressShakeAnimation") as? CAKeyframeAnimation,
              let singleValues = singleAnim.values as? [Double] else {
            Issue.record("Single animation should be CAKeyframeAnimation with Double values")
            return
        }
        let singleMaxAmplitude = singleValues.map { abs($0) }.max() ?? 0
        #expect(abs(singleMaxAmplitude - 3.0) < 0.01, "Single press max amplitude should be 3.0")

        // Rapid multiple presses -> stronger amplitude and shorter duration
        for _ in 1...5 {
            delegate.animateStatusItemOnKeyPress(isAutorepeat: false)
        }

        guard let rapidAnim = layer.animation(forKey: "keyPressShakeAnimation") as? CAKeyframeAnimation,
              let rapidValues = rapidAnim.values as? [Double] else {
            Issue.record("Rapid animation should be CAKeyframeAnimation with Double values")
            return
        }
        let rapidMaxAmplitude = rapidValues.map { abs($0) }.max() ?? 0
        #expect(rapidMaxAmplitude > 5.0, "Rapid typing max amplitude should be significantly stronger (> 5.0)")
        #expect(rapidAnim.duration < singleAnim.duration, "Rapid typing duration should be faster/snappier")
    }

    @MainActor
    @Test func testUnlockingResetsKeyPressHistory() async throws {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)

        EventHandler.shared.isLocked = true
        delegate.applicationDidFinishLaunching(notification)
        try await Task.sleep(for: .milliseconds(100))

        delegate.animateStatusItemOnKeyPress(isAutorepeat: false)
        delegate.animateStatusItemOnKeyPress(isAutorepeat: false)
        #expect(!delegate.recentKeyPressTimes.isEmpty)

        EventHandler.shared.isLocked = false
        try await Task.sleep(for: .milliseconds(100))
        #expect(delegate.recentKeyPressTimes.isEmpty, "Unlocking should clear keypress timestamp history")
    }
}
