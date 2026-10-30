//
//  InputDeviceManager.swift
//  BabyKeyboardLock
//
//  Created by Antigravity on 29.10.2026.
//

import Foundation
import CoreGraphics
import IOKit
import IOKit.hid

class InputDeviceManager: ObservableObject, InputDeviceManaging {
    @Published var devices: [InputDevice] = []

    private var hidManager: IOHIDManager?
    private var isMonitoring = false
    private let queue = DispatchQueue(label: "com.babykeyboardlock.inputdevicemanager", qos: .userInitiated)
    private var scheduledRefreshWorkItem: DispatchWorkItem?
    private var senderIDCache: [UInt64: String] = [:]
    private let cacheLock = NSLock()

    var onDeviceBlockStateChanged: (() -> Void)?

    static let shared = InputDeviceManager()

    init(autoStart: Bool = true) {
        if autoStart && !Self.isRunningTestsOrPreview {
            startMonitoring()
        }
    }

    deinit {
        stopMonitoring()
    }

    private static var isRunningTestsOrPreview: Bool {
        #if DEBUG
        let isTestBundle = Bundle.main.bundlePath.hasSuffix(".xctest") ||
                          Bundle.main.bundlePath.contains("XCTestProducts") ||
                          Bundle(for: InputDeviceManager.self).bundlePath.contains("Tests")
        let isXCTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                       NSClassFromString("XCTest") != nil
        let isSwiftTesting = NSClassFromString("Testing.Test") != nil ||
                            ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil ||
                            ProcessInfo.processInfo.arguments.contains { $0.contains("xctest") }
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        return isTestBundle || isXCTest || isSwiftTesting || isPreview
        #else
        return false
        #endif
    }

    var isAnyKeyboardBlocked: Bool {
        let keyboards = devices.filter { $0.type == .keyboard }
        return keyboards.isEmpty || keyboards.contains { $0.isBlocked }
    }

    var isAnyMouseBlocked: Bool {
        let mice = devices.filter { $0.type == .mouseOrTrackpad }
        return !mice.isEmpty && mice.contains { $0.isBlocked }
    }

    var isAnyControllerBlocked: Bool {
        let controllers = devices.filter { $0.type == .controller }
        return controllers.isEmpty || controllers.contains { $0.isBlocked }
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = manager

        let criteria: [[String: Any]] = [
            [kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Keyboard],
            [kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse],
            [kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Pointer],
            [kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey as String: kHIDUsage_GD_GamePad],
            [kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Joystick],
            [kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey as String: kHIDUsage_GD_MultiAxisController],
            [kIOHIDDeviceUsagePageKey as String: 0x0D /* Digitizer */, kIOHIDDeviceUsageKey as String: 0x05 /* TouchPad */]
        ]
        IOHIDManagerSetDeviceMatchingMultiple(manager, criteria as CFArray)

        let matchingCallback: IOHIDDeviceCallback = { context, _, _, _ in
            guard let context = context else { return }
            let this = Unmanaged<InputDeviceManager>.fromOpaque(context).takeUnretainedValue()
            this.scheduleRefresh()
        }

        let removalCallback: IOHIDDeviceCallback = { context, _, _, _ in
            guard let context = context else { return }
            let this = Unmanaged<InputDeviceManager>.fromOpaque(context).takeUnretainedValue()
            this.scheduleRefresh()
        }

        let refCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerRegisterDeviceMatchingCallback(manager, matchingCallback, refCon)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, refCon)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        // Note: We intentionally do NOT call IOHIDManagerOpen here.
        // Calling IOHIDManagerOpen on keyboard/mouse usage pages causes macOS to demand
        // "Input Monitoring" permission (kTCCServiceListenEvent).
        // Enumerating devices with IOHIDManagerCopyDevices and receiving hot-plug/removal callbacks
        // does not require opening the manager, so only Accessibility permission is needed.

        refreshDevices()
    }

    func stopMonitoring() {
        guard isMonitoring, let manager = hidManager else { return }
        isMonitoring = false
        scheduledRefreshWorkItem?.cancel()
        scheduledRefreshWorkItem = nil

        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        self.hidManager = nil
    }

    private func scheduleRefresh() {
        scheduledRefreshWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.refreshDevices()
        }
        scheduledRefreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    func refreshDevices() {
        guard let manager = hidManager else { return }

        queue.async { [weak self] in
            guard let self = self else { return }
            guard let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
                DispatchQueue.main.async {
                    self.cacheLock.lock()
                    self.senderIDCache.removeAll()
                    self.cacheLock.unlock()
                    if self.devices.isEmpty {
                        self.devices = []
                    }
                }
                return
            }

            var discovered: [String: InputDevice] = [:]

            for dev in deviceSet {
                let name = (IOHIDDeviceGetProperty(dev, kIOHIDProductKey as CFString) as? String) ?? ""
                let transport = IOHIDDeviceGetProperty(dev, kIOHIDTransportKey as CFString) as? String

                // Filter out virtual devices and background TouchBarUserDevice
                if transport?.lowercased() == "virtual" {
                    continue
                }
                let lowerName = name.lowercased()
                if lowerName.contains("touchbar") || lowerName.contains("touch bar") {
                    continue
                }

                let vid = (IOHIDDeviceGetProperty(dev, kIOHIDVendorIDKey as CFString) as? NSNumber)?.intValue
                let pid = (IOHIDDeviceGetProperty(dev, kIOHIDProductIDKey as CFString) as? NSNumber)?.intValue
                let loc = (IOHIDDeviceGetProperty(dev, kIOHIDLocationIDKey as CFString) as? NSNumber)?.intValue
                let serial = (IOHIDDeviceGetProperty(dev, kIOHIDSerialNumberKey as CFString) as? String)

                let page = (IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsagePageKey as CFString) as? NSNumber)?.intValue ?? 0
                let usage = (IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsageKey as CFString) as? NSNumber)?.intValue ?? 0

                guard let type = Self.classifyDevice(usagePage: page, usage: usage, productName: name) else {
                    continue
                }

                // Determine registry entry ID of this specific HID device and its parent service
                var registryIDs = Set<UInt64>()
                let service = IOHIDDeviceGetService(dev)
                if service != MACH_PORT_NULL {
                    var entryID: UInt64 = 0
                    if IORegistryEntryGetRegistryEntryID(service, &entryID) == KERN_SUCCESS && entryID != 0 {
                        registryIDs.insert(entryID)
                    }
                    var parent: io_registry_entry_t = 0
                    if IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent) == KERN_SUCCESS && parent != MACH_PORT_NULL {
                        var parentID: UInt64 = 0
                        if IORegistryEntryGetRegistryEntryID(parent, &parentID) == KERN_SUCCESS && parentID != 0 {
                            registryIDs.insert(parentID)
                        }
                        IOObjectRelease(parent)
                    }
                }

                let formattedName = Self.formatDeviceName(rawName: name, type: type)
                let stableID = Self.computeDeviceID(
                    type: type,
                    vid: vid,
                    pid: pid,
                    transport: transport,
                    locationID: loc,
                    serial: serial,
                    name: formattedName
                )

                if var existing = discovered[stableID] {
                    existing.registryEntryIDs.formUnion(registryIDs)
                    discovered[stableID] = existing
                } else {
                    // Check user preference or default: keyboards and controllers default to blocked,
                    // mouse and touchpad do NOT lock by default.
                    let userPrefKey = "input_device_blocked_\(stableID)"
                    let isBlocked: Bool
                    if UserDefaults.standard.object(forKey: userPrefKey) != nil {
                        isBlocked = UserDefaults.standard.bool(forKey: userPrefKey)
                    } else {
                        isBlocked = type != .mouseOrTrackpad
                    }

                    let newDevice = InputDevice(
                        id: stableID,
                        name: formattedName,
                        type: type,
                        isBlocked: isBlocked,
                        transport: transport,
                        vendorID: vid,
                        productID: pid,
                        locationID: loc,
                        registryEntryIDs: registryIDs
                    )
                    discovered[stableID] = newDevice
                }
            }

            // Sort devices: Keyboards first, Mice second, Controllers third, then alphabetically
            let sortedDevices = Array(discovered.values).sorted { a, b in
                if a.type != b.type {
                    return a.type.sortOrder < b.type.sortOrder
                }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }

            DispatchQueue.main.async {
                self.cacheLock.lock()
                self.senderIDCache.removeAll()
                self.cacheLock.unlock()
                self.devices = sortedDevices
                self.onDeviceBlockStateChanged?()
            }
        }
    }

    func setDeviceBlocked(id: String, isBlocked: Bool) {
        if let idx = devices.firstIndex(where: { $0.id == id }) {
            devices[idx].isBlocked = isBlocked
            UserDefaults.standard.set(isBlocked, forKey: "input_device_blocked_\(id)")
            onDeviceBlockStateChanged?()
        }
    }

    func isDeviceBlocked(senderID: UInt64, eventType: CGEventType) -> Bool {
        let isKeyboardEvent: Bool
        let isMouseEvent: Bool

        switch eventType {
        case .keyDown, .keyUp, .flagsChanged:
            isKeyboardEvent = true
            isMouseEvent = false
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
             .otherMouseDown, .otherMouseUp, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            isKeyboardEvent = false
            isMouseEvent = true
        default:
            if eventType.rawValue == 14 {
                isKeyboardEvent = true
                isMouseEvent = false
            } else {
                isKeyboardEvent = false
                isMouseEvent = false
            }
        }

        let targetType: InputDeviceType? = isKeyboardEvent ? .keyboard : (isMouseEvent ? .mouseOrTrackpad : nil)

        if let targetType = targetType {
            let matchingDevices = devices.filter { $0.type == targetType }

            // If no devices of this type exist in the list, use type-level flag
            if matchingDevices.isEmpty {
                return isKeyboardEvent ? isAnyKeyboardBlocked : isAnyMouseBlocked
            }

            // If there is only ONE device of this type (e.g. only built-in trackpad),
            // all events of this type on this machine belong to it
            if matchingDevices.count == 1 {
                return matchingDevices[0].isBlocked
            }

            // If multiple devices of this type exist, match specifically by senderID
            if senderID != 0 {
                if let device = resolveDevice(for: senderID, matching: targetType) {
                    return device.isBlocked
                }
            }

            // Fallback when sender ID cannot be uniquely matched among multiple devices
            if isKeyboardEvent {
                return isAnyKeyboardBlocked
            } else if isMouseEvent {
                return isAnyMouseBlocked
            }
        }

        return true
    }

    private func resolveDevice(for senderID: UInt64, matching expectedType: InputDeviceType) -> InputDevice? {
        cacheLock.lock()
        if let cachedID = senderIDCache[senderID] {
            cacheLock.unlock()
            return devices.first(where: { $0.id == cachedID })
        }
        cacheLock.unlock()

        let matchingDevices = devices.filter { $0.type == expectedType }

        // Fast path: search already associated registryEntryIDs
        if let match = matchingDevices.first(where: { $0.registryEntryIDs.contains(senderID) }) {
            cacheLock.lock()
            senderIDCache[senderID] = match.id
            cacheLock.unlock()
            return match
        }

        // Slow path: match via IORegistryEntryIDMatching
        var service: io_service_t = 0
        let matchingDict = IORegistryEntryIDMatching(senderID)
        if #available(macOS 12.0, *) {
            service = IOServiceGetMatchingService(kIOMainPortDefault, matchingDict)
        } else {
            service = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict)
        }
        guard service != MACH_PORT_NULL else { return nil }
        defer { IOObjectRelease(service) }

        var vid = (IORegistryEntryCreateCFProperty(service, kIOHIDVendorIDKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber)?.intValue
        if vid == nil {
            vid = (IORegistryEntrySearchCFProperty(service, kIOServicePlane, kIOHIDVendorIDKey as CFString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)) as? NSNumber)?.intValue
        }
        var pid = (IORegistryEntryCreateCFProperty(service, kIOHIDProductIDKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber)?.intValue
        if pid == nil {
            pid = (IORegistryEntrySearchCFProperty(service, kIOServicePlane, kIOHIDProductIDKey as CFString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)) as? NSNumber)?.intValue
        }
        var name = IORegistryEntryCreateCFProperty(service, kIOHIDProductKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
        if name == nil {
            name = IORegistryEntrySearchCFProperty(service, kIOServicePlane, kIOHIDProductKey as CFString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)) as? String
        }

        if let match = matchingDevices.first(where: { dev in
            if let vid = vid, let pid = pid, dev.vendorID == vid && dev.productID == pid {
                return true
            }
            if let name = name, !name.isEmpty && (dev.name.localizedCaseInsensitiveContains(name) || name.localizedCaseInsensitiveContains(dev.name)) {
                return true
            }
            return false
        }) {
            // Cache this senderID for future fast lookups without mutating @Published devices
            cacheLock.lock()
            senderIDCache[senderID] = match.id
            cacheLock.unlock()
            return match
        }

        return nil
    }

    // MARK: - Helpers

    static func classifyDevice(usagePage: Int, usage: Int, productName: String) -> InputDeviceType? {
        let lower = productName.lowercased()
        if lower.contains("touchbar") || lower.contains("touch bar") {
            return nil
        }

        if usagePage == kHIDPage_GenericDesktop {
            switch usage {
            case kHIDUsage_GD_Keyboard:
                return .keyboard
            case kHIDUsage_GD_Mouse, kHIDUsage_GD_Pointer:
                return .mouseOrTrackpad
            case kHIDUsage_GD_GamePad, kHIDUsage_GD_Joystick, kHIDUsage_GD_MultiAxisController:
                return .controller
            default:
                break
            }
        }

        if usagePage == 0x0D /* Digitizer */ && usage == 0x05 /* TouchPad */ {
            return .mouseOrTrackpad
        }

        return nil
    }

    static func formatDeviceName(rawName: String, type: InputDeviceType) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            switch type {
            case .keyboard: return "External Keyboard"
            case .mouseOrTrackpad: return "Mouse / Trackpad"
            case .controller: return "Game Controller"
            }
        }

        if trimmed == "Apple Internal Keyboard / Trackpad" {
            switch type {
            case .keyboard: return "Apple Internal Keyboard"
            case .mouseOrTrackpad: return "Apple Internal Trackpad"
            case .controller: return trimmed
            }
        }

        return trimmed
    }

    static func computeDeviceID(
        type: InputDeviceType,
        vid: Int?,
        pid: Int?,
        transport: String?,
        locationID: Int?,
        serial: String?,
        name: String
    ) -> String {
        var components: [String] = ["\(type.rawValue)"]
        if let vid = vid { components.append("v\(vid)") }
        if let pid = pid { components.append("p\(pid)") }
        if let serial = serial, !serial.isEmpty {
            components.append("s\(serial)")
        } else if let loc = locationID, loc != 0 {
            components.append("l\(loc)")
        } else {
            components.append("n\(name.replacingOccurrences(of: " ", with: "_"))")
        }
        return components.joined(separator: "_")
    }
}
