//
//  AuthSessionRefresher.swift
//  AuthData
//
//  Created by YunhakLee on 4/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking
import Keychain
import BaseData

public struct AuthSessionRefresher: AuthSessionRefreshing {
    private let service: AuthService
    private let tokenStore: TokenStore
    private let logger: DataLogger?
    
    init(
        service: AuthService,
        tokenStore: TokenStore,
        logger: DataLogger?
    ) {
        self.service = service
        self.tokenStore = tokenStore
        self.logger = logger
    }
    
    public func refreshSession() async throws -> Bool {
        do {
            guard let refreshToken = try tokenStore.refreshToken() else {
                return false
            }
            let request = ReissueRequest(refreshToken: refreshToken)
            let response = try await service.postReissueToken(request)
            try tokenStore.saveAccessToken(response.accessToken)
            try tokenStore.saveRefreshToken(response.refreshToken)
            return true
        } catch {
            throw error
        }
    }
}
