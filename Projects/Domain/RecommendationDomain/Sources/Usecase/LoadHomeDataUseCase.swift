//
//  LoadHomeDataUseCase.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadHomeDataUseCase {
    func execute() async throws(RepositoryError) -> HomeData
}

public final class DefaultLoadHomeDataUseCase: LoadHomeDataUseCase {

    private let recommendationRepository: RecommendationRepository

    public init(repository: RecommendationRepository) {
        self.recommendationRepository = repository
    }

    /// ⚠️ 관심글(`fetchInterestFeeds`)은 홈 화면에 섹션이 없어 **일부러 호출하지 않는다.**
    /// requireToken 호출을 하나 줄이는 효과도 있다(아래 순차 실행 특성 때문에 홈 전체가 함께 죽는 걸 막는다).
    public func execute() async throws(RepositoryError) -> HomeData {
        let todayDiscoveries = try await recommendationRepository.fetchTodayDiscoveries()
        let trendingFeeds = try await recommendationRepository.fetchTrendingFeeds()
        let preferenceGenreNovelState = try await recommendationRepository.fetchPreferenceGenreNovels()

        return HomeData(
            nickname: recommendationRepository.fetchCachedNickname(),
            todayDiscoveries: todayDiscoveries,
            trendingFeeds: trendingFeeds,
            preferenceGenreNovelState: preferenceGenreNovelState
        )
    }
}
