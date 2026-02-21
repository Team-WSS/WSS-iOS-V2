//
//  LogoutUseCaseTests.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import AuthDomain

@Suite("LogoutUseCase")
struct LogoutUseCaseTests {

    @Test("로그아웃 성공 시 서버 로그아웃 요청 후 로컬 토큰과 사용자 데이터를 제거한다")
    func clearsLocalDataAfterLogout() async throws {
        let repo = MockAuthRepository()
        let tokenStore = MockTokenStore()
        let userDataStore = MockUserDataStore()

        repo.logoutResult = .success(())

        let sut = DefaultLogoutUseCase(
            authRepository: repo,
            tokenStore: tokenStore,
            userDataStore: userDataStore
        )

        try await sut.execute()

        #expect(repo.logoutCallCount == 1)
        #expect(tokenStore.clearCallCount == 1)
        #expect(userDataStore.clearUserDataCallCount == 1)
    }

    @Test("로그아웃 중 레포지토리에서 에러가 발생하면 로컬 데이터를 제거하지 않고 그대로 전달한다")
    func doesNotClearLocalDataWhenRepositoryFails() async {
        let repo = MockAuthRepository()
        let tokenStore = MockTokenStore()
        let userDataStore = MockUserDataStore()

        repo.logoutResult = .failure(.serverUnavailable)

        let sut = DefaultLogoutUseCase(
            authRepository: repo,
            tokenStore: tokenStore,
            userDataStore: userDataStore
        )

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.execute()
        }

        #expect(repo.logoutCallCount == 1)
        #expect(tokenStore.clearCallCount == 0)
        #expect(userDataStore.clearUserDataCallCount == 0)
    }
}
