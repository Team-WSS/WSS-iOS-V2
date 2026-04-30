//  SessionTokenStore.swift
//  Networking
//
//  Created by YunhakLee on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public protocol SessionTokenStore {
    func accessToken() throws -> String?
    func clearTokens() throws
}
