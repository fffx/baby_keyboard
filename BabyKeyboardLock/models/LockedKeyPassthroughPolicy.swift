//
//  LockedKeyPassthroughPolicy.swift
//  BabyKeyboardLock
//
//  Created by OpenAI on 19.08.2026.
//

import CoreGraphics

enum LockedKeyPassthroughPolicy {
    case disabled
    case patatap

    func allows(event: CGEvent, keyCode: Int64) -> Bool {
        switch self {
        case .disabled:
            return false
        case .patatap:
            return Self.patatapKeyCodes.contains(keyCode) &&
                event.flags.intersection(Self.patatapDisallowedModifiers).isEmpty
        }
    }

    private static let patatapDisallowedModifiers: CGEventFlags = [
        .maskCommand,
        .maskControl,
        .maskAlternate,
        .maskShift,
        .maskSecondaryFn
    ]

    private static let patatapKeyCodes: Set<Int64> = [
        Int64(KeyCodeString.a),
        Int64(KeyCodeString.b),
        Int64(KeyCodeString.c),
        Int64(KeyCodeString.d),
        Int64(KeyCodeString.e),
        Int64(KeyCodeString.f),
        Int64(KeyCodeString.g),
        Int64(KeyCodeString.h),
        Int64(KeyCodeString.i),
        Int64(KeyCodeString.j),
        Int64(KeyCodeString.k),
        Int64(KeyCodeString.l),
        Int64(KeyCodeString.m),
        Int64(KeyCodeString.n),
        Int64(KeyCodeString.o),
        Int64(KeyCodeString.p),
        Int64(KeyCodeString.q),
        Int64(KeyCodeString.r),
        Int64(KeyCodeString.s),
        Int64(KeyCodeString.t),
        Int64(KeyCodeString.u),
        Int64(KeyCodeString.v),
        Int64(KeyCodeString.w),
        Int64(KeyCodeString.x),
        Int64(KeyCodeString.y),
        Int64(KeyCodeString.z),
        Int64(KeyCodeString.space)
    ]
}
