//
//  AuthService.swift
//  AuthData
//
//  Created by YunhakLee on 4/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

protocol AuthService {
    func patchAppleAccountSync(_ request: AppleSyncRequest) async throws
    func postAppleLogin(_ request: AppleLoginRequest) async throws -> LoginSuccessResponse
    func postKakaoLogin(_ requestHeader: KakaoLoginRequestHeader) async throws -> LoginSuccessResponse
    func postLogout(_ request: LogoutRequest) async throws
    func postWithdraw(_ request: WithdrawRequest) async throws
    func postReissueToken(_ request: ReissueRequest) async throws -> ReissueResponse
}
