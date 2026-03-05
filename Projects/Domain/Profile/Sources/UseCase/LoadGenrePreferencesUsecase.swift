//
//  LoadGenrePreferencesUsecase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadGenrePreferencesUsecase {
    func execute(_ target: ProfileTarget) async throws -> [GenrePreference]
}

public final class DefaultLoadGenrePreferencesUsecase: LoadGenrePreferencesUsecase {
    
    private let profileRepository: ProfileRepository
    
    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    public func execute(_ target: ProfileTarget) async throws -> [GenrePreference] {
        try await profileRepository.fetchGenrePreferences(target)
    }
}
