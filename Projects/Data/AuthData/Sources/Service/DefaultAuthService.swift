//
//  DefaultAuthService.swift
//  AuthData
//
//  Created by YunhakLee on 4/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

struct DefaultAuthService: AuthService {
    private let client: NetworkingRequestable

    init(client: NetworkingRequestable) {
        self.client = client
    }

    func patchAppleAccountSync(_ request: AppleSyncRequest) async throws {
        let endpoint = AuthEndpoint.patchAppleAccountSync(request)
        _ = try await client.request(endpoint)
    }

    func postAppleLogin(_ request: AppleLoginRequest) async throws -> LoginSuccessResponse {
        let endpoint = AuthEndpoint.postAppleLogin(request)
        return try await client.request(endpoint, decodeTo: LoginSuccessResponse.self)
    }

    func postKakaoLogin(_ requestHeader: KakaoLoginRequestHeader) async throws -> LoginSuccessResponse {
        let endpoint = AuthEndpoint.postKakaoLogin(requestHeader)
        return try await client.request(endpoint, decodeTo: LoginSuccessResponse.self)
    }

    func postLogout(_ request: LogoutRequest) async throws {
        let endpoint = AuthEndpoint.postLogout(request)
        _ = try await client.request(endpoint)
    }

    func postWithdraw(_ request: WithdrawRequest) async throws {
        let endpoint = AuthEndpoint.postWithdraw(request)
        _ = try await client.request(endpoint)
    }

    func postReissueToken(_ request: ReissueRequest) async throws -> ReissueResponse {
        let endpoint = AuthEndpoint.postReissueToken(request)
        return try await client.request(endpoint, decodeTo: ReissueResponse.self)
    }
}
