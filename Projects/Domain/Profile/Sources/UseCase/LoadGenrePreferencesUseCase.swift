//
//  LoadGenrePreferencesUseCase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadGenrePreferencesUseCase {
    func execute(_ target: ProfileTarget) async throws -> [GenrePreference]
}

public final class DefaultLoadGenrePreferencesUseCase: LoadGenrePreferencesUseCase {
    
    private let profileRepository: ProfileRepository
    
    public init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    public func execute(_ target: ProfileTarget) async throws -> [GenrePreference] {
        try await profileRepository.fetchGenrePreferences(target)
    }
}
