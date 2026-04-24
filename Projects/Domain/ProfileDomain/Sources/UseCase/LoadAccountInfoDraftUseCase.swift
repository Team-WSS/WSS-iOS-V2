//
//  LoadAccountInfoDraftUseCase.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadAccountInfoDraftUseCase {
    func execute() async throws(RepositoryError) -> AccountInfoDraft
}

public class DefaultLoadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase {
    let repository: ProfileRepository
    
    public init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    public func execute() async throws(RepositoryError) -> AccountInfoDraft {
        return try await repository.loadAccountInfoDraft()
    }
}
