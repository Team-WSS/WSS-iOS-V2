//
//  MockTokenStore.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import AuthDomain


final class MockTokenStore: TokenStore {
    private(set) var savedSessions: [AuthSession] = []
    private(set) var clearCallCount: Int = 0

    func save(_ session: AuthSession) {
        savedSessions.append(session)
    }

    func clear() {
        clearCallCount += 1
    }
}
