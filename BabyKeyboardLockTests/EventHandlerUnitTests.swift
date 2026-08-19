@testable import BabyKeyboardLock
import CoreGraphics
import Testing
import SwiftUI

struct EventHandlerUnitTests {
    private var testProxy: CGEventTapProxy {
        CGEventTapProxy(bitPattern: 1)!
    }

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

    @Test func testPatatapModeDefaultsToDisabled() async throws {
        setUp()
        let handler = EventHandler(isLocked: false)
        #expect(!handler.patatapModeEnabled)
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

    @Test func testLockedKeyboardHonorsPatatapPassthroughPolicy() async throws {
        setUp()
        let handler = EventHandler(isLocked: true)
        handler.patatapModeEnabled = true

        let keyDown = makeKeyboardEvent(keyCode: KeyCodeString.a, keyDown: true)
        let keyDownResult = handler.handleKeyEvent(proxy: testProxy, type: .keyDown, event: keyDown)
        #expect(keyDownResult != nil)
    }

    @Test func testLockedKeyboardBlocksLettersWhenPatatapModeIsDisabled() async throws {
        setUp()
        let handler = EventHandler(isLocked: true)

        let event = makeKeyboardEvent(keyCode: KeyCodeString.a, keyDown: true)
        let result = handler.handleKeyEvent(proxy: testProxy, type: .keyDown, event: event)

        #expect(result == nil)
    }

    @Test func testUnlockShortcutStillTogglesWhileLocked() async throws {
        setUp()
        let mockManager = MockEventTapManager()
        let handler = EventHandler(isLocked: true, eventTapManager: mockManager)
        let event = makeKeyboardEvent(
            keyCode: KeyCodeString.u,
            keyDown: true,
            flags: [.maskControl, .maskAlternate]
        )

        let result = handler.handleKeyEvent(proxy: testProxy, type: .keyDown, event: event)

        #expect(result == nil)
        #expect(!handler.isLocked)
        #expect(mockManager.stopRunLoopCalled)
    }

    private func makeKeyboardEvent(
        keyCode: UInt16,
        keyDown: Bool,
        flags: CGEventFlags = []
    ) -> CGEvent {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: keyDown)!
        event.flags = flags
        event.setIntegerValueField(.keyboardEventKeyboardType, value: 40)
        return event
    }
}
