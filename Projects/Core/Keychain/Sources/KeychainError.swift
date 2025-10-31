//
//  KeychainError.swift
//  Keychain
//
//  Created by YunhakLee on 10/22/25.
//

import Foundation

public enum KeychainError: Error, CustomStringConvertible {
    case noData
    case dataEncodingFailed
    case duplicateItem
    case unhandledError(status: OSStatus)

    public var description: String {
        "KEYCHAIN ERROR: \(message)"
    }

    private var message: String {
        switch self {
        case .noData: return "No data found"
        case .dataEncodingFailed: return "Failed to encode data"
        case .duplicateItem: return "Item already exists"
        case .unhandledError(let status): return "Unhandled error: \(status)"
        }
    }
}
