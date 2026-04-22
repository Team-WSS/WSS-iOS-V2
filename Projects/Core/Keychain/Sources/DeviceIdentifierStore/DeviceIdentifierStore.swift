//
//  DeviceIdentifierStore.swift
//  Keychain
//
//  Created by YunhakLee on 4/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol DeviceIdentifierStore {
    func deviceIdentifier() throws -> String?
    func saveDeviceIdentifier(_ identifier: String) throws
    func clearDeviceIdentifier() throws
}