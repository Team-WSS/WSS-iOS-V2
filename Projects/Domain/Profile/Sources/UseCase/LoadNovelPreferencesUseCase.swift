//
//  LoadNovelPreferencesUseCase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadNovelPreferencesUseCase {
    func execute(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference
}

public final class DefaultLoadNovelPreferencesUseCase: LoadNovelPreferencesUseCase {
    
    private let profileRepository: ProfileRepository
    
    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    public func execute(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference {
        try await profileRepository.fetchNovelPreferences(target)
    }
}
