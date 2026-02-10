//
//  MockTermsAgreementRepository.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import SettingDomain

final class MockTermsAgreementRepository: TermsAgreementRepository {
    var loadCallCount = 0
    var saveCallCount = 0
    var savedDrafts: [TermsAgreementDraft] = []

    var loadResult: Result<TermsAgreementDraft, RepositoryError> = .success(TermsAgreementDraft())
    var saveResult: Result<Void, RepositoryError> = .success(())

    func loadTermsAgreementDraft() async throws(RepositoryError) -> TermsAgreementDraft {
        loadCallCount += 1
        return try loadResult.get()
    }

    func saveTermsAgreementDraft(_ draft: TermsAgreementDraft) async throws(RepositoryError) {
        saveCallCount += 1
        savedDrafts.append(draft)
        try saveResult.get()
    }
}
