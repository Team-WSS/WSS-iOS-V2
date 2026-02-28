//
//  SocialLoginUseCaseTests.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
import AuthDomainTesting
@testable import AuthDomain

@Suite("SocialLoginUseCase")
struct SocialLoginUseCaseTests {
    
    @Test("소셜 로그인 성공 시 토큰을 저장하고 온보딩 필요 여부를 반환한다")
    func savesSessionAndReturnsNeedOnboarding() async throws {
        let repo = MockAuthRepository()
        
        let session = NeedOnboarding(value: true)
        repo.loginResult = .success(session)
        
        let sut = DefaultSocialLoginUseCase(authRepository: repo)
        
        let needOnboarding = try await sut.execute(credential: .kakao(accessToken: "kakao_token"))
        
        #expect(repo.loginCallCount == 1)
        #expect(needOnboarding.value == true)
    }

    @Test("소셜 로그인 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryErrorForApple() async {
        let repo = MockAuthRepository()
        
        repo.loginResult = .failure(.networkUnavailable)
        
        let sut = DefaultSocialLoginUseCase(authRepository: repo)
        
        await #expect(throws: AuthError.networkUnavailable) {
            _ = try await sut.execute(
                credential: .apple(
                    authorizationCode: "apple_code",
                    idToken: "apple_id_token"
                )
            )
        }
        
        #expect(repo.loginCallCount == 1)
    }
}
