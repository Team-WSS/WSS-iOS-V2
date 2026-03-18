//
//  SyncAppleCredentialUseCaseTests.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import AuthDomain
import AuthDomainTesting

@Suite("SyncAppleCredentialUseCase")
struct SyncAppleCredentialUseCaseTests {

    @Test("애플 인증 정보 동기화 요청을 수행한다")
    func syncsAppleCredential() async throws {
        let repo = MockAuthRepository()
        repo.syncResult = .success(())

        let sut = DefaultSyncAppleCredentialUseCase(repository: repo)

        let cred = AppleSyncCredential(authorizationCode: "code", idToken: "token")
        try await sut.execute(credential: cred)

        #expect(repo.syncCallCount == 1)
        #expect(repo.syncReceivedCredential == cred)
    }

    @Test("애플 인증 정보 동기화 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockAuthRepository()
        repo.syncResult = .failure(.invalidCredential)

        let sut = DefaultSyncAppleCredentialUseCase(repository: repo)

        await #expect(throws: AuthError.invalidCredential) {
            try await sut.execute(
                credential: AppleSyncCredential(authorizationCode: "bad", idToken: "bad")
            )
        }

        #expect(repo.syncCallCount == 1)
    }
}
