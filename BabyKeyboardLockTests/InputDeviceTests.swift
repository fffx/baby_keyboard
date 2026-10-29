//
//  InputDeviceTests.swift
//  BabyKeyboardLockTests
//
//  Created by Antigravity on 29.10.2026.
//

@testable import BabyKeyboardLock
import Testing
import Foundation
import CoreGraphics
import IOKit.hid

struct InputDeviceTests {

    @Test func testInputDeviceInitialization() async throws {
        let kbDevice = InputDevice(
            id: "keyboard_1",
            name: "Apple Internal Keyboard",
            type: .keyboard
        )

        #expect(kbDevice.id == "keyboard_1")
        #expect(kbDevice.name == "Apple Internal Keyboard")
        #expect(kbDevice.type == .keyboard)
        // Verify default blocked is true for keyboard
        #expect(kbDevice.isBlocked == true)
        #expect(kbDevice.type.systemImage == "keyboard")

        let mouseDevice = InputDevice(
            id: "mouse_1",
            name: "Apple Internal Trackpad",
            type: .mouseOrTrackpad
        )

        #expect(mouseDevice.id == "mouse_1")
        #expect(mouseDevice.name == "Apple Internal Trackpad")
        #expect(mouseDevice.type == .mouseOrTrackpad)
        // Verify default blocked is false for mouse / trackpad
        #expect(mouseDevice.isBlocked == false)
        #expect(mouseDevice.type.systemImage == "computermouse")
    }

    @Test func testDeviceClassification() async throws {
        // Keyboard
        let keyboardType = InputDeviceManager.classifyDevice(
            usagePage: kHIDPage_GenericDesktop,
            usage: kHIDUsage_GD_Keyboard,
            productName: "Keyboard"
        )
        #expect(keyboardType == .keyboard)

        // Mouse
        let mouseType = InputDeviceManager.classifyDevice(
            usagePage: kHIDPage_GenericDesktop,
            usage: kHIDUsage_GD_Mouse,
            productName: "Mouse"
        )
        #expect(mouseType == .mouseOrTrackpad)

        // Trackpad (Digitizer)
        let trackpadType = InputDeviceManager.classifyDevice(
            usagePage: 0x0D,
            usage: 0x05,
            productName: "Trackpad"
        )
        #expect(trackpadType == .mouseOrTrackpad)

        // Game Controller
        let controllerType = InputDeviceManager.classifyDevice(
            usagePage: kHIDPage_GenericDesktop,
            usage: kHIDUsage_GD_GamePad,
            productName: "Xbox Wireless Controller"
        )
        #expect(controllerType == .controller)

        // Virtual TouchBar device should be ignored
        let touchBarType = InputDeviceManager.classifyDevice(
            usagePage: kHIDPage_GenericDesktop,
            usage: kHIDUsage_GD_Keyboard,
            productName: "TouchBarUserDevice"
        )
        #expect(touchBarType == nil)

        // Composite device with vendor-specific page should NOT blindly classify as keyboard
        let compositeVendorType = InputDeviceManager.classifyDevice(
            usagePage: 65280,
            usage: 3,
            productName: "Apple Internal Keyboard / Trackpad"
        )
        #expect(compositeVendorType == nil)
    }

    @Test func testFormattedDeviceNames() async throws {
        // Apple Internal Keyboard / Trackpad separation
        let kbName = InputDeviceManager.formatDeviceName(
            rawName: "Apple Internal Keyboard / Trackpad",
            type: .keyboard
        )
        #expect(kbName == "Apple Internal Keyboard")

        let trackpadName = InputDeviceManager.formatDeviceName(
            rawName: "Apple Internal Keyboard / Trackpad",
            type: .mouseOrTrackpad
        )
        #expect(trackpadName == "Apple Internal Trackpad")

        let externalName = InputDeviceManager.formatDeviceName(
            rawName: "Keychron K2",
            type: .keyboard
        )
        #expect(externalName == "Keychron K2")
    }

    @Test func testComputeDeviceID() async throws {
        let id1 = InputDeviceManager.computeDeviceID(
            type: .keyboard,
            vid: 1452,
            pid: 834,
            transport: "SPI",
            locationID: 100,
            serial: nil,
            name: "Apple Internal Keyboard"
        )

        let id2 = InputDeviceManager.computeDeviceID(
            type: .mouseOrTrackpad,
            vid: 1452,
            pid: 834,
            transport: "SPI",
            locationID: 100,
            serial: nil,
            name: "Apple Internal Trackpad"
        )

        #expect(id1 != id2)
        #expect(id1.contains("keyboard"))
        #expect(id2.contains("mouseOrTrackpad"))
    }

    @Test func testMockInputDeviceManagerBlockingLogic() async throws {
        let mock = MockInputDeviceManager()

        let kbDevice = InputDevice(
            id: "kb_1",
            name: "Built-in Keyboard",
            type: .keyboard,
            isBlocked: true,
            registryEntryIDs: [1001]
        )
        let mouseDevice = InputDevice(
            id: "mouse_1",
            name: "Magic Mouse",
            type: .mouseOrTrackpad,
            isBlocked: false,
            registryEntryIDs: [2002]
        )

        mock.devices = [kbDevice, mouseDevice]

        #expect(mock.isAnyKeyboardBlocked == true)
        #expect(mock.isAnyMouseBlocked == false)

        // Test blocking lookup with registryEntryID
        let kbBlocked = mock.isDeviceBlocked(senderID: 1001, eventType: .keyDown)
        #expect(kbBlocked == true)

        let mouseBlocked = mock.isDeviceBlocked(senderID: 2002, eventType: .leftMouseDown)
        #expect(mouseBlocked == false)

        // Mouse click with unknown senderID (or 0) still unblocked when trackpad is unblocked
        let unknownMouseBlocked = mock.isDeviceBlocked(senderID: 9999, eventType: .leftMouseDown)
        #expect(unknownMouseBlocked == false)

        // Toggle keyboard to unblocked
        mock.setDeviceBlocked(id: "kb_1", isBlocked: false)
        #expect(mock.setDeviceBlockedCalled == true)
        #expect(mock.isAnyKeyboardBlocked == false)
        #expect(mock.isDeviceBlocked(senderID: 1001, eventType: .keyDown) == false)
    }
}
