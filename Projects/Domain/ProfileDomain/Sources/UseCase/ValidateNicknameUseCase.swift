//
//  SyncUserBasicInfoUseCase.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol ValidateNicknameUseCase {
    func execute(_ nickname: String) async throws(RepositoryError) -> Bool
}

public class DefaultValidateNicknameUseCase: ValidateNicknameUseCase {
    let repository: ProfileRepository
    
    public init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    public func execute(_ nickname: String) async throws(RepositoryError) -> Bool {
        return try await repository.validateNickname(nickname)
    }
}
