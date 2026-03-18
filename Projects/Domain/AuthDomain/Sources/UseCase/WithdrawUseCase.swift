//
//  WithdrawUseCase 2.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol WithdrawUseCase {
    func execute(
        draft: WithdrawalReasonDraft
    ) async throws(RepositoryError)
}

public final class DefaultWithdrawUseCase: WithdrawUseCase {
    private let repository: AuthRepository

    public init(repository: AuthRepository) {
        self.repository = repository
    }

    public func execute(draft: WithdrawalReasonDraft) async throws(RepositoryError) {
        try await repository.withdraw(draft: draft)
    }
}
