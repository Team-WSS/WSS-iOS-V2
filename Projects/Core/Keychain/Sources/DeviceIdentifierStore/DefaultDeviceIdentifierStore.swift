//
//  DefaultDeviceIdentifierStore.swift
//  Keychain
//
//  Created by YunhakLee on 4/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public struct DefaultDeviceIdentifierStore: DeviceIdentifierStore {
    private let keychainStore: KeychainStore

    public init(keychainStore: KeychainStore) {
        self.keychainStore = keychainStore
    }

    public func deviceIdentifier() throws -> String? {
        try keychainStore.value(forKey: KeychainKey.Notification.deviceIdentifier)
    }

    public func saveDeviceIdentifier(_ identifier: String) throws {
        try keychainStore.save(value: identifier, forKey: KeychainKey.Notification.deviceIdentifier)
    }

    public func clearDeviceIdentifier() throws {
        try keychainStore.delete(forKey: KeychainKey.Notification.deviceIdentifier)
    }
}