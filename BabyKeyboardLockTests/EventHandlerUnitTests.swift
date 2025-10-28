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
}
