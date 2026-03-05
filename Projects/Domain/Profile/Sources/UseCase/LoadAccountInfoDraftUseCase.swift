//
//  LoadAccountInfoDraftUseCase.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadAccountInfoDraftUseCase {
    func execute() async throws -> AccountInfoDraft
}

public class DefaultLoadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase {
    let repository: ProfileRepository
    
    public init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    public func execute() async throws -> AccountInfoDraft {
        return try await repository.loadAccountInfoDraft()
    }
}
