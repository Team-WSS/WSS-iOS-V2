//
//  LoadNovelPreferencesUsecase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadNovelPreferencesUsecase {
    func execute(_ target: ProfileTarget) async throws -> NovelPreference
}

public final class DefaultLoadNovelPreferencesUsecase: LoadNovelPreferencesUsecase {
    
    private let profileRepository: ProfileRepository
    
    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    public func execute(_ target: ProfileTarget) async throws -> NovelPreference {
        try await profileRepository.fetchNovelPreferences(target)
    }
}
