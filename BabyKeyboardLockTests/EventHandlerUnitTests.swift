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

        // Verify createEventTap was called (but returns nil in mock)
        #expect(mockManager.createEventTapCalled)
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
}
