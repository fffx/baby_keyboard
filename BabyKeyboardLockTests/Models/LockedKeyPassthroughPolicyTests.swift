@testable import BabyKeyboardLock
import CoreGraphics
import Testing

struct LockedKeyPassthroughPolicyTests {
    @Test func testDisabledPolicyBlocksLettersAndSpace() async throws {
        let letter = makeKeyboardEvent(keyCode: KeyCodeString.a, keyDown: true)
        #expect(!LockedKeyPassthroughPolicy.disabled.allows(event: letter, keyCode: Int64(KeyCodeString.a)))

        let space = makeKeyboardEvent(keyCode: KeyCodeString.space, keyDown: true)
        #expect(!LockedKeyPassthroughPolicy.disabled.allows(event: space, keyCode: Int64(KeyCodeString.space)))
    }

    @Test func testPatatapPolicyAllowsLettersAndSpace() async throws {
        let letter = makeKeyboardEvent(keyCode: KeyCodeString.a, keyDown: true)
        #expect(LockedKeyPassthroughPolicy.patatap.allows(event: letter, keyCode: Int64(KeyCodeString.a)))

        let space = makeKeyboardEvent(keyCode: KeyCodeString.space, keyDown: true)
        #expect(LockedKeyPassthroughPolicy.patatap.allows(event: space, keyCode: Int64(KeyCodeString.space)))
    }

    @Test func testPatatapPolicyAllowsCapsLockLetter() async throws {
        let event = makeKeyboardEvent(keyCode: KeyCodeString.a, keyDown: true, flags: .maskAlphaShift)

        #expect(LockedKeyPassthroughPolicy.patatap.allows(event: event, keyCode: Int64(KeyCodeString.a)))
    }

    @Test func testPatatapPolicyBlocksShortcutModifiers() async throws {
        let disallowedFlags: [CGEventFlags] = [
            .maskShift,
            .maskCommand,
            .maskControl,
            .maskAlternate,
            .maskSecondaryFn
        ]

        for flags in disallowedFlags {
            let event = makeKeyboardEvent(keyCode: KeyCodeString.a, keyDown: true, flags: flags)
            #expect(!LockedKeyPassthroughPolicy.patatap.allows(event: event, keyCode: Int64(KeyCodeString.a)))
        }
    }

    @Test func testPatatapPolicyBlocksNonLetterKeys() async throws {
        let blockedKeyCodes = [
            KeyCodeString.returnKey,
            KeyCodeString.delete,
            KeyCodeString.escape,
            KeyCodeString.leftArrow,
            KeyCodeString.one
        ]

        for keyCode in blockedKeyCodes {
            let event = makeKeyboardEvent(keyCode: keyCode, keyDown: true)
            #expect(!LockedKeyPassthroughPolicy.patatap.allows(event: event, keyCode: Int64(keyCode)))
        }
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
