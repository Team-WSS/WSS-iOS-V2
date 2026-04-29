//
//  TokenStore.swift
//  Keychain
//
//  Created by YunhakLee on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol TokenStore {
    func saveAccessToken(_ token: String) throws
    func saveRefreshToken(_ token: String) throws
    func accessToken() throws -> String?
    func refreshToken() throws -> String?
    func clearTokens() throws
}