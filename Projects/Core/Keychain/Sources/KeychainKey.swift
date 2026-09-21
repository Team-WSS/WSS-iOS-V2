//
//  KeychainKey.swift
//  Keychain
//
//  Created by YunhakLee on 10/22/25.
//

import Foundation

public enum KeychainKey {
    public static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? ""
    }

    public static func make(_ rawKey: String) -> String {
        "\(bundleIdentifier).\(rawKey)"
    }
}

public protocol KeychainKeyRepresentable: RawRepresentable where RawValue == String { }

public extension KeychainKeyRepresentable {
    var key: String {
        KeychainKey.make(rawValue)
    }
}
