//
//  MockTermsAgreementRepository.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SettingDomain

public final class MockTermsAgreementRepository: TermsAgreementRepository {
    public var loadCallCount = 0
    public var saveCallCount = 0
    public var savedDrafts: [TermsAgreementDraft] = []

    public var loadResult: Result<TermsAgreementDraft, RepositoryError> = .success(TermsAgreementDraft())
    public var saveResult: Result<Void, RepositoryError> = .success(())

    public init() {}

    public func loadTermsAgreementDraft() async throws(RepositoryError) -> TermsAgreementDraft {
        loadCallCount += 1
        return try loadResult.get()
    }

    public func save(draft: TermsAgreementDraft) async throws(RepositoryError) {
        saveCallCount += 1
        savedDrafts.append(draft)
        try saveResult.get()
    }
}
