//
//  LoadTermsAgreementDraftUseCase.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadTermsAgreementDraftUseCase {
    func execute() async throws(RepositoryError) -> TermsAgreementDraft
}

public final class DefaultLoadTermsAgreementDraftUseCase: LoadTermsAgreementDraftUseCase {
    private let repository: TermsAgreementRepository

    public init(repository: TermsAgreementRepository) {
        self.repository = repository
    }

    public func execute() async throws(RepositoryError) -> TermsAgreementDraft {
        try await repository.loadTermsAgreementDraft()
    }
}
