# Mocking Event Tap in Tests

## Problem
When testing `EventHandler`, we don't want to call the actual `CGEvent.tapCreate` API because:
- It requires accessibility permissions
- It interacts with the system event tap system
- It can cause tests to fail or behave unpredictably
- Tests should be isolated and not affect the system

## Solution: Dependency Injection with Protocol

We use a protocol-based approach to inject a mock event tap manager in tests.

### Architecture

```
EventTapManaging (protocol)
    ├── DefaultEventTapManager (production)
    └── MockEventTapManager (testing)
```

### Key Files

1. **`BabyKeyboardLock/protocols/EventTapManaging.swift`**
   - Defines the `EventTapManaging` protocol
   - Contains `DefaultEventTapManager` (calls real CGEvent APIs)
   - Contains `MockEventTapManager` (NO actual system calls)

2. **`BabyKeyboardLock/services/EventHandler.swift`**
   - Uses `EventTapManaging` protocol via dependency injection
   - Automatically uses `MockEventTapManager` in test environment
   - Uses `DefaultEventTapManager` in production

3. **`BabyKeyboardLockTests/Mocks/MockEventTapManager.swift`**
   - Test utilities and extensions for `MockEventTapManager`

## Usage in Tests

### Automatic Mock Injection (Recommended)

```swift
@Test func testEventHandler() async throws {
    // In test environment, MockEventTapManager is automatically used
    let handler = EventHandler(isLocked: false)

    // Verify it's using the mock
    let manager = handler.testEventTapManager
    #expect(manager is MockEventTapManager)
}
```

### Explicit Mock Injection (For Advanced Testing)

```swift
@Test func testEventTapBehavior() async throws {
    let mockManager = MockEventTapManager()
    let handler = EventHandler(isLocked: false, eventTapManager: mockManager)

    // Trigger event tap setup
    handler.testSetupEventTap()

    // Verify mock was called (NOT actual CGEvent.tapCreate!)
    #expect(mockManager.createEventTapCalled)

    // Note: Mock returns nil, so event tap is NOT actually setup
    #expect(!handler.isEventTapSetup)
    #expect(handler.testEventTap == nil)

    // Clean up
    handler.testClearEventTap()
}
```

### Testing Run Loop Behavior

```swift
@Test func testRunLoopOperations() async throws {
    let mockManager = MockEventTapManager()
    let handler = EventHandler(isLocked: false, eventTapManager: mockManager)

    // Test stop behavior
    handler.stop()
    #expect(mockManager.stopRunLoopCalled)

    // Reset for next test
    mockManager.reset()
}
```

## MockEventTapManager Properties

The mock tracks all calls without executing actual system operations:

- `createEventTapCalled: Bool` - Whether `createEventTap` was called
- `enableTapCalled: Bool` - Whether `enableTap` was called
- `isTapEnabledResult: Bool` - What `isTapEnabled` should return
- `runLoopCalled: Bool` - Whether `runLoop` was called
- `stopRunLoopCalled: Bool` - Whether `stopRunLoop` was called

## Test Helpers (DEBUG only)

Available in `EventHandler` for testing:

```swift
#if DEBUG
// Check if event tap is set up
handler.isEventTapSetup // Bool

// Access event tap directly
handler.testEventTap // CFMachPort?

// Access the event tap manager
handler.testEventTapManager // EventTapManaging

// Manually trigger setup (uses mock in tests)
handler.testSetupEventTap()

// Clean up event tap
handler.testClearEventTap()
#endif
```

## Example Test Suite

```swift
@Test func testEventTapNotCalledInTests() async throws {
    let mockManager = MockEventTapManager()
    let handler = EventHandler(isLocked: false, eventTapManager: mockManager)

    // Event tap should not be setup when initialized with isLocked: false
    #expect(!handler.isEventTapSetup)

    // Verify CGEvent.tapCreate was NOT called
    #expect(!mockManager.createEventTapCalled)
}

@Test func testEventTapSetupUsesMock() async throws {
    let mockManager = MockEventTapManager()
    let handler = EventHandler(isLocked: false, eventTapManager: mockManager)

    // Manually trigger setup
    handler.testSetupEventTap()

    // Verify MOCK was used (not real CGEvent APIs)
    #expect(mockManager.createEventTapCalled)

    // Mock returns nil, so event tap won't be fully setup
    #expect(!handler.isEventTapSetup)
    #expect(!mockManager.enableTapCalled)  // Not called when eventTap is nil

    // Clean up
    handler.testClearEventTap()
}
```

## Benefits

✅ **No System Calls** - `CGEvent.tapCreate` is NEVER called in tests
✅ **No Permissions Needed** - Tests don't require accessibility permissions
✅ **Fast & Isolated** - Tests run quickly without system dependencies
✅ **Verifiable** - Can verify mock methods were called correctly
✅ **Automatic** - Test environment automatically uses mocks
✅ **Type-Safe** - Protocol ensures consistency between mock and production

## Production vs Test Behavior

| Environment | Manager Used | Calls Real APIs? |
|-------------|-------------|------------------|
| Production | `DefaultEventTapManager` | ✅ Yes |
| Tests | `MockEventTapManager` | ❌ No |
| Previews | `MockEventTapManager` | ❌ No |

## Detection Logic

The code automatically detects test/preview environments:

```swift
private static var isRunningTestsOrPreview: Bool {
    #if DEBUG
    let isTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                 NSClassFromString("XCTest") != nil
    let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    return isTest || isPreview
    #else
    return false
    #endif
}
```

## Migration Guide

If you have existing tests that need updating:

**Before:**
```swift
let handler = EventHandler(isLocked: false)
// Tests might fail or require accessibility permissions
```

**After:**
```swift
let mockManager = MockEventTapManager()
let handler = EventHandler(isLocked: false, eventTapManager: mockManager)
// Tests work without accessibility permissions
// Can verify mock behavior
#expect(!mockManager.createEventTapCalled)
```

## Troubleshooting

**Q: Test still calls CGEvent.tapCreate?**
A: Ensure you're using `MockEventTapManager` or running in test environment

**Q: How do I verify event tap was set up?**
A: Use `handler.isEventTapSetup` and check `mockManager.createEventTapCalled`

**Q: Can I test different event tap scenarios?**
A: Yes! Set `mockManager.isTapEnabledResult` to simulate different states

**Q: Do I need to clean up after tests?**
A: Yes, use `handler.testClearEventTap()` or `mockManager.reset()` for clean state

