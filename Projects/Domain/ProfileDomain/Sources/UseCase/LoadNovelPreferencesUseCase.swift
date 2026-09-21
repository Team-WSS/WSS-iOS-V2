//
//  LoadNovelPreferencesUseCase.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadNovelPreferencesUseCase: Sendable {
    func execute(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference
}

public final class DefaultLoadNovelPreferencesUseCase: LoadNovelPreferencesUseCase {

    private let profileRepository: ProfileRepository
    /// 캐시 미스 시 서버 재동기화까지 책임지는 건 `KeywordRepository`가 아니라 이 UseCase 몫이다 —
    /// `BaseDomain/CLAUDE.md`의 `LoadTotalKeywordsUseCase` 항목 참고(2026-09-12, 사용자 확정).
    private let loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase

    public init(profileRepository: ProfileRepository,
                loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase) {
        self.profileRepository = profileRepository
        self.loadTotalKeywordsUseCase = loadTotalKeywordsUseCase
    }

    public func execute(_ target: ProfileTarget) async throws(RepositoryError) -> NovelPreference {
        let cachedKeywords = (try? await loadTotalKeywordsUseCase.execute())?.flatMap(\.keywords) ?? []
        return try await profileRepository.fetchNovelPreferences(target, cachedKeywords: cachedKeywords)
    }
}
