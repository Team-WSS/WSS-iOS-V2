//
//  LoadTermsAgreementDraftUseCase.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol LoadTermsAgreementDraftUseCase {
    func execute() async throws -> TermsAgreementDraft
}

public final class DefaultLoadTermsAgreementDraftUseCase: LoadTermsAgreementDraftUseCase {
    private let repository: TermsAgreementRepository

    public init(repository: TermsAgreementRepository) {
        self.repository = repository
    }

    public func execute() async throws -> TermsAgreementDraft {
        try await repository.loadTermsAgreementDraft()
    }
}
