//
//  SaveTermsAgreementDraftUseCaseTests.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import SettingDomain
import SettingDomainTesting

@Suite("SaveTermsAgreementDraftUseCase")
struct SaveTermsAgreementDraftUseCaseTests {

    @Test("Draft를 저장 요청하면 레포지토리에 그대로 전달한다")
    func savesDraftToRepository() async throws
    {
        let repo = MockTermsAgreementRepository()
        let sut = DefaultSaveTermsAgreementDraftUseCase(repository: repo)

        var draft = TermsAgreementDraft()
        
        for t in TermsType.allCases where t.isRequired {
            draft.setAgreed(true, for: t)
        }

        try await sut.execute(draft: draft)

        #expect(repo.saveCallCount == 1)
        #expect(repo.savedDrafts == [draft])
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockTermsAgreementRepository()
        repo.saveResult = .failure(.authenticationRequired)

        let sut = DefaultSaveTermsAgreementDraftUseCase(repository: repo)

        let draft = TermsAgreementDraft()

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.execute(draft: draft)
        }

        #expect(repo.saveCallCount == 1)
        #expect(repo.savedDrafts == [draft])
    }
}
