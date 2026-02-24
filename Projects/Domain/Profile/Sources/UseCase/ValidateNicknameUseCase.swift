//
//  SyncUserBasicInfoUseCase.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol ValidateNicknameUseCase {
    func excute(_ nickname: String) async throws -> Bool
}

public class DefaultValidateNicknameUseCase: ValidateNicknameUseCase {
    let repository: ProfileRepository
    
    public init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    public func excute(_ nickname: String) async throws -> Bool {
        return try await repository.validateNickname(nickname)
    }
}
