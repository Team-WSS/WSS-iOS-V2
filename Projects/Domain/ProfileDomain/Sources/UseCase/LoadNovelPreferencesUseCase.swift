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
    private let keywordRepository: KeywordRepository

    public init(profileRepository: ProfileRepository,
                keywordRepository: KeywordRepository) {
        self.profileRepository = profileRepository
        self.keywordRepository = keywordRepository
    }

    public func execute(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference {
        let cachedKeywords = (try? await keywordRepository.fetchKeywords())?.flatMap(\.keywords) ?? []
        return try await profileRepository.fetchNovelPreferences(target, cachedKeywords: cachedKeywords)
    }
}
