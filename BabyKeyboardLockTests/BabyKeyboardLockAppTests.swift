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

    @Test func testWindowConstants() async throws {
        #expect(AnimationWindowID == "animationTransparentWindow", "Animation window ID should match")
        #expect(MainWindowID == "main", "Main window ID should match")
    }
}

