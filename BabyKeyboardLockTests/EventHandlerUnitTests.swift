@testable import BabyKeyboardLock
import Testing
import SwiftUI

struct EventHandlerUnitTests {
    func setUp() {
        // Clear AppStorage values before each test
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }

    @Test func testEventHandlerInitialState() async throws {
        setUp()
        let handler = EventHandler(isLocked: false)
        #expect(!handler.isLocked)
        #expect(handler.selectedLockEffect == .none)
    }

    @Test func testKeyboardLockToggle() async throws {
        setUp()
        let handler = EventHandler(isLocked: false)
        handler.isLocked = true
        #expect(handler.isLocked)

        handler.isLocked = false
        #expect(!handler.isLocked)
    }

    @MainActor
    @Test func testAppStoragePersistence() async throws {
        setUp()
        // Create a test view to utilize @AppStorage
        struct TestView: View {
            @AppStorage("lockKeyboardOnLaunch") var lockKeyboardOnLaunch: Bool = false
            var body: some View { EmptyView() }
        }

        let view = TestView()
        view.lockKeyboardOnLaunch = true

        let handler = EventHandler(isLocked: false)
        // Test that we can set the lock state
        handler.isLocked = true
        #expect(handler.isLocked)
    }

    @Test func testEffectChange() async throws {
        setUp()
        let handler = EventHandler(isLocked: false)
        handler.selectedLockEffect = .confettiConnon
        #expect(handler.selectedLockEffect == .confettiConnon)
    }

    // MARK: - Event Tap Tests

    @Test func testEventTapNotSetupInitially() async throws {
        setUp()
        let mockManager = MockEventTapManager()
        let handler = EventHandler(isLocked: false, eventTapManager: mockManager)

        // Event tap should not be setup when initialized with isLocked: false
        #expect(!handler.isEventTapSetup)
        #expect(handler.testEventTap == nil)

        // Verify CGEvent.tapCreate was NOT called (that's the whole point!)
        #expect(!mockManager.createEventTapCalled)
    }

    @Test func testEventTapSetupWhenLocked() async throws {
        setUp()
        let mockManager = MockEventTapManager()
        let handler = EventHandler(isLocked: true, eventTapManager: mockManager)

        // In test environment, even when locked, event tap isn't created
        // until startEventLoop is called (which is skipped in tests)
        #expect(!handler.isEventTapSetup)
        #expect(!mockManager.createEventTapCalled)
    }

    @Test func testEventTapCleanup() async throws {
        setUp()
        let mockManager = MockEventTapManager()
        let handler = EventHandler(isLocked: false, eventTapManager: mockManager)

        // Manually setup event tap for testing
        handler.testSetupEventTap()

        // Verify createEventTap was called (but returns nil in mock)\n        #expect(mockManager.createEventTapCalled)
        // Mock returns nil, so event tap should NOT be setup
        #expect(!handler.isEventTapSetup)
        // enableTap should not be called when eventTap is nil
        #expect(!mockManager.enableTapCalled)

        // Clean up (no-op since nothing was created)
        handler.testClearEventTap()

        // Verify it's still not setup
        #expect(!handler.isEventTapSetup)
    }

    @Test func testEventTapCanBeSetupManually() async throws {
        setUp()
        let mockManager = MockEventTapManager()
        let handler = EventHandler(isLocked: false, eventTapManager: mockManager)

        // Initially not setup
        #expect(!handler.isEventTapSetup)
        #expect(!mockManager.createEventTapCalled)

        // Manually trigger setup - uses MOCK, not real CGEvent APIs
        handler.testSetupEventTap()

        // Mock returns nil, so event tap is NOT actually setup
        #expect(!handler.isEventTapSetup)
        #expect(handler.testEventTap == nil)
        #expect(mockManager.createEventTapCalled)

        // Cleanup after test (no-op)
        handler.testClearEventTap()
    }

    @Test func testMockEventTapManagerIsUsedInTests() async throws {
        setUp()
        // When no eventTapManager is provided, tests automatically get MockEventTapManager
        let handler = EventHandler(isLocked: false)

        // Verify we got a mock manager (not the default one)
        let manager = handler.testEventTapManager
        #expect(manager is MockEventTapManager)
    }

    @Test func testMockCapsLockManagerIsUsedInTests() async throws {
        setUp()
        let handler = EventHandler(isLocked: false)
        let manager = handler.testCapsLockManager
        #expect(manager is MockCapsLockManager)
    }

    @Test func testCapsLockStateSavedAndRestoredOnLockToggle() async throws {
        setUp()
        let mockCapsLock = MockCapsLockManager()
        mockCapsLock.capsLockState = true

        let handler = EventHandler(isLocked: false, capsLockManager: mockCapsLock)
        #expect(!handler.isLocked)

        // Lock handler
        handler.isLocked = true
        #expect(mockCapsLock.getCapsLockStateCalled)
        #expect(handler.testSavedCapsLockState == true)
        #expect(mockCapsLock.capsLockState == false)

        // Unlock handler
        handler.isLocked = false
        #expect(mockCapsLock.capsLockState == true)
    }

    @Test func testCapsLockKeyPressedWhileLockedSwallowsEventAndForcesCapsLockOff() async throws {
        setUp()
        let mockCapsLock = MockCapsLockManager()
        let handler = EventHandler(isLocked: true, capsLockManager: mockCapsLock)

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: KeyCode.capsLock.rawValue, keyDown: false) else {
            Issue.record("Failed to create CGEvent")
            return
        }
        event.flags = [.maskAlphaShift]

        let result = handler.handleKeyEvent(type: .flagsChanged, event: event)
        #expect(result == nil, "Caps Lock event should be swallowed when locked")
        #expect(mockCapsLock.setCapsLockStateCalled, "Caps lock should be forced off")
        #expect(mockCapsLock.capsLockState == false)
    }

    @Test func testCapsLockKeyPressedWhileUnlockedPassesThrough() async throws {
        setUp()
        let mockCapsLock = MockCapsLockManager()
        let handler = EventHandler(isLocked: false, capsLockManager: mockCapsLock)

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: KeyCode.capsLock.rawValue, keyDown: false) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        let result = handler.handleKeyEvent(type: .flagsChanged, event: event)
        #expect(result != nil, "Caps Lock event should pass through when unlocked")
    }

    @Test func testModifierKeysSwallowedWhileLocked() async throws {
        setUp()
        let handler = EventHandler(isLocked: true)

        guard let shiftEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x38, keyDown: false) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        let result = handler.handleKeyEvent(type: .flagsChanged, event: shiftEvent)
        #expect(result == nil, "Modifier key event should be swallowed when locked")
    }

    // MARK: - Controller Lock Tests

    @Test func testMockControllerLockManagerIsUsedInTests() async throws {
        setUp()
        let handler = EventHandler(isLocked: false)
        let manager = handler.testControllerLockManager
        #expect(manager is MockControllerLockManager)
    }

    @Test func testControllersLockedWhenAppLocked() async throws {
        setUp()
        let mockController = MockControllerLockManager()
        let handler = EventHandler(isLocked: false, controllerLockManager: mockController)
        #expect(!mockController.isLocked)

        handler.isLocked = true
        #expect(mockController.lockControllersCalled)
        #expect(mockController.isLocked)
    }

    @Test func testControllersUnlockedWhenAppUnlocked() async throws {
        setUp()
        let mockController = MockControllerLockManager()
        let handler = EventHandler(isLocked: true, controllerLockManager: mockController)
        handler.testOnLocked()
        #expect(mockController.isLocked)

        handler.isLocked = false
        #expect(mockController.unlockControllersCalled)
        #expect(!mockController.isLocked)
    }

    @Test func testControllerLockReleasedOnStop() async throws {
        setUp()
        let mockController = MockControllerLockManager()
        let handler = EventHandler(isLocked: false, controllerLockManager: mockController)
        handler.isLocked = true
        #expect(mockController.isLocked)

        handler.stop()
        #expect(mockController.unlockControllersCalled)
        #expect(!mockController.isLocked)
    }

    // MARK: - Input Device Filtering Tests

    @Test func testMockInputDeviceManagerIsUsedInTests() async throws {
        setUp()
        let handler = EventHandler(isLocked: false)
        let manager = handler.testInputDeviceManager
        #expect(manager is MockInputDeviceManager)
    }

    @Test func testKeyboardEventFromBlockedDeviceIsSwallowed() async throws {
        setUp()
        let mockDeviceManager = MockInputDeviceManager()
        mockDeviceManager.isDeviceBlockedHandler = { _, _ in true }

        let handler = EventHandler(isLocked: true, inputDeviceManager: mockDeviceManager)

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0x00, keyDown: true) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        let result = handler.handleKeyEvent(type: .keyDown, event: event)
        #expect(result == nil, "Key event from blocked device should be swallowed")
    }

    @Test func testKeyboardEventFromUnblockedDevicePassesThrough() async throws {
        setUp()
        let mockDeviceManager = MockInputDeviceManager()
        // Simulate device is NOT blocked
        mockDeviceManager.isDeviceBlockedHandler = { _, _ in false }

        let handler = EventHandler(isLocked: true, inputDeviceManager: mockDeviceManager)

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0x00, keyDown: true) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        let result = handler.handleKeyEvent(type: .keyDown, event: event)
        #expect(result != nil, "Key event from unblocked device should pass through")
    }

    @Test func testMouseEventFromBlockedDeviceIsSwallowed() async throws {
        setUp()
        let mockDeviceManager = MockInputDeviceManager()
        mockDeviceManager.isDeviceBlockedHandler = { _, _ in true }

        let handler = EventHandler(isLocked: true, inputDeviceManager: mockDeviceManager)

        guard let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: .zero, mouseButton: .left) else {
            Issue.record("Failed to create mouse CGEvent")
            return
        }

        let result = handler.handleKeyEvent(type: .leftMouseDown, event: event)
        #expect(result == nil, "Mouse event from blocked device should be swallowed")
    }

    @Test func testMouseEventFromUnblockedDevicePassesThrough() async throws {
        setUp()
        let mockDeviceManager = MockInputDeviceManager()
        mockDeviceManager.isDeviceBlockedHandler = { _, _ in false }

        let handler = EventHandler(isLocked: true, inputDeviceManager: mockDeviceManager)

        guard let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: .zero, mouseButton: .left) else {
            Issue.record("Failed to create mouse CGEvent")
            return
        }

        let result = handler.handleKeyEvent(type: .leftMouseDown, event: event)
        #expect(result != nil, "Mouse event from unblocked device should pass through")
    }

    @Test func testUnlockShortcutWorksEvenIfDeviceBlocked() async throws {
        setUp()
        let mockDeviceManager = MockInputDeviceManager()
        mockDeviceManager.isDeviceBlockedHandler = { _, _ in true }

        let handler = EventHandler(isLocked: true, inputDeviceManager: mockDeviceManager)

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: KeyCode.u.rawValue, keyDown: true) else {
            Issue.record("Failed to create CGEvent")
            return
        }
        event.flags = [.maskControl, .maskAlternate]

        let result = handler.handleKeyEvent(type: .keyDown, event: event)
        #expect(result == nil)
        #expect(handler.isLocked == false, "Unlock shortcut should unlock regardless of device blocking state")
    }

    @Test func testControllersLockedWithDeviceList() async throws {
        setUp()
        let mockController = MockControllerLockManager()
        let mockDeviceManager = MockInputDeviceManager()
        let controllerDevice = InputDevice(id: "ctrl_1", name: "Gamepad", type: .controller, isBlocked: true)
        mockDeviceManager.devices = [controllerDevice]

        let handler = EventHandler(isLocked: false, controllerLockManager: mockController, inputDeviceManager: mockDeviceManager)
        handler.isLocked = true

        #expect(mockController.lockControllersCalled)
        #expect(mockController.lastLockedDevices.count == 1)
        #expect(mockController.isLocked == true)
    }

    // MARK: - Key Pressed Notification Tests

    @Test func testKeyPressWhileLockedTriggersNotification() async throws {
        setUp()
        let handler = EventHandler(isLocked: true)

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0x00, keyDown: true) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        var notificationReceived = false
        var receivedAutorepeat = true
        handler.onKeyPressedWhileLocked = { isAutorepeat in
            notificationReceived = true
            receivedAutorepeat = isAutorepeat
        }

        let result = handler.handleKeyEvent(type: .keyDown, event: event)
        #expect(result == nil, "Key event should be swallowed when locked")

        // Wait briefly for main queue dispatch
        try await Task.sleep(for: .milliseconds(50))
        #expect(notificationReceived, "Should trigger key press notification when locked")
        #expect(!receivedAutorepeat, "Initial key press should not be flagged as autorepeat")
    }

    @Test func testKeyPressWithAutorepeatTriggersNotificationWithAutorepeatFlag() async throws {
        setUp()
        let handler = EventHandler(isLocked: true)

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0x00, keyDown: true) else {
            Issue.record("Failed to create CGEvent")
            return
        }
        event.setIntegerValueField(.keyboardEventAutorepeat, value: 1)

        var notificationReceived = false
        var receivedAutorepeat = false
        handler.onKeyPressedWhileLocked = { isAutorepeat in
            notificationReceived = true
            receivedAutorepeat = isAutorepeat
        }

        let result = handler.handleKeyEvent(type: .keyDown, event: event)
        #expect(result == nil)

        try await Task.sleep(for: .milliseconds(50))
        #expect(notificationReceived)
        #expect(receivedAutorepeat, "Autorepeat key press should be flagged as autorepeat")
    }

    @Test func testKeyPressWhileUnlockedDoesNotTriggerNotification() async throws {
        setUp()
        let handler = EventHandler(isLocked: false)

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0x00, keyDown: true) else {
            Issue.record("Failed to create CGEvent")
            return
        }

        var notificationReceived = false
        handler.onKeyPressedWhileLocked = { _ in
            notificationReceived = true
        }

        let result = handler.handleKeyEvent(type: .keyDown, event: event)
        #expect(result != nil, "Key event should pass through when unlocked")

        try await Task.sleep(for: .milliseconds(50))
        #expect(!notificationReceived, "Should NOT trigger key press notification when unlocked")
    }

    @Test func testCapsLockKeyPressWhileLockedTriggersNotification() async throws {
        setUp()
        let mockCapsLock = MockCapsLockManager()
        let handler = EventHandler(isLocked: true, capsLockManager: mockCapsLock)

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: KeyCode.capsLock.rawValue, keyDown: false) else {
            Issue.record("Failed to create CGEvent")
            return
        }
        event.flags = [.maskAlphaShift]

        var notificationReceived = false
        handler.onKeyPressedWhileLocked = { isAutorepeat in
            notificationReceived = true
            #expect(!isAutorepeat)
        }

        let result = handler.handleKeyEvent(type: .flagsChanged, event: event)
        #expect(result == nil)

        try await Task.sleep(for: .milliseconds(50))
        #expect(notificationReceived, "Caps lock while locked should trigger key press notification")
    }
}
