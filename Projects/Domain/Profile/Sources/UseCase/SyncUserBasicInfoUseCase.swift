//
//  SyncUserBasicInfoUseCase.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol SyncUserBasicInfoUseCase {
    func excute() async throws
}


public class DefaultSyncUserBasicInfoUseCase: SyncUserBasicInfoUseCase {
    let repository: ProfileRepository
    
    public init(repository: ProfileRepository) {
        self.repository = repository
    }
    
    public func excute() async throws {
        _ = try await repository.fetchUserBasicInfo()
    }
}
