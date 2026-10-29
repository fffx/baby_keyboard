//
//  InputDevice.swift
//  BabyKeyboardLock
//
//  Created by Antigravity on 29.10.2026.
//

import Foundation

enum InputDeviceType: String, CaseIterable, Codable, Identifiable {
    case keyboard
    case mouseOrTrackpad
    case controller

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .keyboard:
            return "Keyboard"
        case .mouseOrTrackpad:
            return "Mouse / Trackpad"
        case .controller:
            return "Game Controller"
        }
    }

    var systemImage: String {
        switch self {
        case .keyboard:
            return "keyboard"
        case .mouseOrTrackpad:
            return "computermouse"
        case .controller:
            return "gamecontroller"
        }
    }
}

struct InputDevice: Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    let type: InputDeviceType
    var isBlocked: Bool
    var transport: String?
    var vendorID: Int?
    var productID: Int?
    var locationID: Int?
    var registryEntryIDs: Set<UInt64>

    init(
        id: String,
        name: String,
        type: InputDeviceType,
        isBlocked: Bool? = nil,
        transport: String? = nil,
        vendorID: Int? = nil,
        productID: Int? = nil,
        locationID: Int? = nil,
        registryEntryIDs: Set<UInt64> = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isBlocked = isBlocked ?? (type != .mouseOrTrackpad)
        self.transport = transport
        self.vendorID = vendorID
        self.productID = productID
        self.locationID = locationID
        self.registryEntryIDs = registryEntryIDs
    }
}
