//
//  KeychainClient.swift
//  Keychain
//
//  Created by YunhakLee on 10/22/25.
//

import Foundation

/// 실제 iOS Keychain API를 사용하는 구현체
public final class KeychainClient: KeychainStore {

    private let service: String

    // MARK: - Initializer
    /// KeychainClient는 DI 가능한 인스턴스 기반으로 설계되었음.
    public init(service: String? = Bundle.main.bundleIdentifier) {
            self.service = service ?? "DefaultKeychainService"
    }

    // MARK: - CRUD (Data 단위)
    public func create(data: Data?, forKey key: String) throws {
        guard let data else { throw KeychainError.noData }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        switch status {
            case errSecSuccess:
                return
            case errSecDuplicateItem:
                throw KeychainError.duplicateItem
            default:
                throw KeychainError.unhandledError(status: status)
            }
    }

    public func read(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }

    public func update(data: Data?, forKey key: String) throws {
        guard let data else { throw KeychainError.noData }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }

    public func save(data: Data?, forKey key: String) throws {
        do {
            try create(data: data, forKey: key)
        } catch KeychainError.duplicateItem {
            try update(data: data, forKey: key)
        }
    }

    public func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
