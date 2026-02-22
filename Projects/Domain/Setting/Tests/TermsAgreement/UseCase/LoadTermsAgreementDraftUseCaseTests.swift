//
//  LoadTermsAgreementDraftUseCaseTests.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import SettingDomain
import SettingDomainTesting

@Suite("LoadTermsAgreementDraftUseCase")
struct LoadTermsAgreementDraftUseCaseTests {

    @Test("레포지토리에서 Draft를 불러와 그대로 반환한다")
    func returnsDraftFromRepository() async throws {
        let repo = MockTermsAgreementRepository()

        var expected = TermsAgreementDraft()
        let any = TermsType.allCases.first!
        expected.setAgreed(true, for: any)
        repo.loadResult = .success(expected)

        let sut = DefaultLoadTermsAgreementDraftUseCase(repository: repo)

        let draft = try await sut.execute()

        #expect(repo.loadCallCount == 1)
        #expect(draft == expected)
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockTermsAgreementRepository()
        repo.loadResult = .failure(.networkUnavailable)

        let sut = DefaultLoadTermsAgreementDraftUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            _ = try await sut.execute()
        }

        #expect(repo.loadCallCount == 1)
    }
}