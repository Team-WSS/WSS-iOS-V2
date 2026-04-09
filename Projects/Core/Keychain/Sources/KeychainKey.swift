//
//  KeychainKey.swift
//  Keychain
//
//  Created by YunhakLee on 10/22/25.
//

import Foundation

public enum KeychainKey {
    static var bundleIdentifier: String = Bundle.main.bundleIdentifier ?? ""

    public enum Auth {
        public static let accessToken = "\(KeychainKey.bundleIdentifier).accessToken"
        public static let refreshToken = "\(KeychainKey.bundleIdentifier).refreshToken"
    }

    public enum Notification {
        public static let deviceIdentifier  = "\(KeychainKey.bundleIdentifier).deviceIdentifier"
    }
}
