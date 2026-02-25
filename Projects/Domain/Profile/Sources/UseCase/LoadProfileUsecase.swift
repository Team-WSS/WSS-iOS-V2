//
//  LoadProfileUsecase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol LoadProfileUsecase {
    func execute(target: ProfileTarget) async throws -> Profile
}

public final class DefaultLoadProfileUsecase: LoadProfileUsecase {
    
    private let profileRepository: ProfileRepository
    
    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    public func execute(target: ProfileTarget) async throws -> Profile {
        try await profileRepository.fetchUserProfile(target: target)
    }
}
