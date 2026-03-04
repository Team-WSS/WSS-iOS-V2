//
//  WithdrawUseCase 2.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

public protocol WithdrawUseCase {
    func execute(
        draft: WithdrawalReasonDraft
    ) async throws
}

public struct DefaultWithdrawUseCase: WithdrawUseCase {
    private let repository: AuthRepository

    public init(repository: AuthRepository) {
        self.repository = repository
    }

    public func execute(draft: WithdrawalReasonDraft) async throws {
        try await repository.withdraw(draft: draft)
    }
}
