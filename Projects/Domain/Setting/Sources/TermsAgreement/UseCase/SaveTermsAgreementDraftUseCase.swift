//
//  SaveTermsAgreementDraftUseCase.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


// SaveTermsAgreementDraftUseCase.swift

public protocol SaveTermsAgreementDraftUseCase {
    func execute(draft: TermsAgreementDraft) async throws
}

public final class DefaultSaveTermsAgreementDraftUseCase: SaveTermsAgreementDraftUseCase {
    private let repository: TermsAgreementRepository

    public init(repository: TermsAgreementRepository) {
        self.repository = repository
    }

    public func execute(draft: TermsAgreementDraft) async throws {
        try await repository.save(draft: draft)
    }
}
