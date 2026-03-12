//
//  TermsAgreementRepository.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

import BaseDomain

public protocol TermsAgreementRepository {
    func loadTermsAgreementDraft() async throws(RepositoryError) -> TermsAgreementDraft
    func save(draft: TermsAgreementDraft) async throws(RepositoryError)
}
