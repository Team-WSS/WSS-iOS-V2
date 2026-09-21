//
//  AuthEndpointTests.swift
//  AuthData
//
//  Created by Guryss on 8/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import AuthData

/// `additionalHeaders`가 전 케이스 `nil`로 고정돼 있어 `Kakao-Access-Token` 헤더가 한 번도 전송된
/// 적이 없었던 회귀(#196)를 다시 잡기 위한 테스트. 이 분기는 `switch`가 컴파일은 통과시키면서
/// 조용히 `nil`을 반환해도 아무도 알려주지 않는 부류라 회귀 가치가 크다(`AuthData/CLAUDE.md` 참고).
@Suite("AuthEndpoint")
struct AuthEndpointTests {

    @Test("카카오 로그인은 Kakao-Access-Token 헤더를 싣는다")
    func postKakaoLoginCarriesAccessTokenHeader() {
        let requestHeader = KakaoLoginRequestHeader(accessToken: "kakao-access-token")

        let headers = AuthEndpoint.postKakaoLogin(requestHeader).additionalHeaders

        #expect(headers == ["Kakao-Access-Token": "kakao-access-token"])
    }

    @Test("카카오 로그인 외 케이스는 추가 헤더가 없다")
    func otherCasesHaveNoAdditionalHeaders() {
        let cases: [AuthEndpoint] = [
            .patchAppleAccountSync(AppleSyncRequest(authorizationCode: "code", idToken: "idToken")),
            .postAppleLogin(AppleLoginRequest(authorizationCode: "code", idToken: "idToken")),
            .postLogout(LogoutRequest(refreshToken: "refresh", deviceIdentifier: "device")),
            .postWithdraw(WithdrawRequest(reason: "reason")),
            .postReissueToken(ReissueRequest(refreshToken: "refresh"))
        ]

        for endpoint in cases {
            #expect(endpoint.additionalHeaders == nil)
        }
    }
}
