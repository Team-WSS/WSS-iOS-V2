//
//  DefaultTokenStore.swift
//  Keychain
//
//  Created by YunhakLee on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public struct DefaultTokenStore: TokenStore {
    private let keychainStore: KeychainStore

    public init(keychainStore: KeychainStore) {
        self.keychainStore = keychainStore
    }

    public func saveAccessToken(_ token: String) throws {
        try keychainStore.save(value: token, forKey: KeychainKey.Auth.accessToken)
    }

    public func saveRefreshToken(_ token: String) throws {
        try keychainStore.save(value: token, forKey: KeychainKey.Auth.refreshToken)
    }

    public func accessToken() throws -> String? {
        try keychainStore.value(forKey: KeychainKey.Auth.accessToken)
    }

    public func refreshToken() throws -> String? {
        try keychainStore.value(forKey: KeychainKey.Auth.refreshToken)
    }

    public func clearTokens() throws {
        try keychainStore.delete(forKey: KeychainKey.Auth.accessToken)
        try keychainStore.delete(forKey: KeychainKey.Auth.refreshToken)
    }
}
