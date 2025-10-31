//
//  KeychainKey.swift
//  Keychain
//
//  Created by YunhakLee on 10/22/25.
//

import Foundation

public enum KeychainKey {
    static var bundleIdentifier: String = Bundle.main.bundleIdentifier ?? ""
    
    public enum Notification {
        public static let deviceIdentifier  = "\(KeychainKey.bundleIdentifier).deviceIdentifier"
    }
}
