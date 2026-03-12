//
//  WithdrawUseCaseTests.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing

@testable import AuthDomain
import AuthDomainTesting
import BaseDomain

@Suite("WithdrawUseCase")
struct WithdrawUseCaseTests {

    @Test("회원 탈퇴 시 초안을 전달하여 탈퇴 요청을 수행한다")
    func withdrawsWithDraft() async throws {
        let repo = MockAuthRepository()
        repo.withdrawResult = .success(())

        let sut = DefaultWithdrawUseCase(repository: repo)

        let draft = WithdrawalReasonDraft()
        try await sut.execute(draft: draft)

        #expect(repo.withdrawCallCount == 1)
        #expect(repo.withdrawReceivedDraft == draft)
    }

    @Test("회원 탈퇴 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockAuthRepository()
        repo.withdrawResult = .failure(.networkUnavailable)

        let sut = DefaultWithdrawUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await sut.execute(draft: WithdrawalReasonDraft())
        }

        #expect(repo.withdrawCallCount == 1)
    }
}
