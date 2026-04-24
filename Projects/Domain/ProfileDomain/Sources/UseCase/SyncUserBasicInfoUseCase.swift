//
//  SyncUserBasicInfoUseCase.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol SyncUserBasicInfoUseCase {
    func execute() async throws(RepositoryError)
}

public class DefaultSyncUserBasicInfoUseCase: SyncUserBasicInfoUseCase {
    let repository: ProfileRepository
    
    public init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    public func execute() async throws(RepositoryError) {
        _ = try await repository.syncUserBasicInfo()
    }
}
