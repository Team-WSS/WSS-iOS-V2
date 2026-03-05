//
//  SyncUserBasicInfoUseCase.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol SyncUserBasicInfoUseCase {
    func execute() async throws
}

public class DefaultSyncUserBasicInfoUseCase: SyncUserBasicInfoUseCase {
    let repository: ProfileRepository
    
    public init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    public func execute() async throws {
        _ = try await repository.syncUserBasicInfo()
    }
}
