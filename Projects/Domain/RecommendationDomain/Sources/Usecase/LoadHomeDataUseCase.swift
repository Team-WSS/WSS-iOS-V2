//
//  LoadHomeDataUseCase.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadHomeDataUseCase: Sendable {
    func execute() async throws(RepositoryError) -> HomeData
}

public final class DefaultLoadHomeDataUseCase: LoadHomeDataUseCase {

    private let recommendationRepository: RecommendationRepository

    public init(repository: RecommendationRepository) {
        self.recommendationRepository = repository
    }

    /// 세 호출은 서로 독립이라 **`async let`으로 동시에** 부른다. 순차로 펴면 왕복 지연이 그대로 쌓이는데,
    /// 홈은 탭 복귀마다 갱신하는 화면이라 그 비용을 매번 낸다(실측: 순차 0.34~0.52s ↔ 병렬 0.16~0.19s).
    ///
    public func execute() async throws(RepositoryError) -> HomeData {
        async let todayDiscoveries = recommendationRepository.fetchTodayDiscoveries()
        async let trendingFeeds = recommendationRepository.fetchTrendingFeeds()
        async let preferenceGenreNovelState = recommendationRepository.fetchPreferenceGenreNovels()

        // ⚠️ `async let`은 타입 지정 throw를 `any Error`로 지운다 → 여기서 되돌려야 컴파일된다
        // (`withThrowingTaskGroup`도 마찬가지라 바꿔도 이 블록은 사라지지 않는다).
        // Repository는 `throws(RepositoryError)`라 두 번째 분기는 실제로는 도달하지 않는다.
        let loaded: ([TodayDiscovery], [TrendingFeed], PreferenceGenreNovelState)
        do {
            loaded = try await (todayDiscoveries, trendingFeeds, preferenceGenreNovelState)
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.unknown
        }

        return HomeData(
            nickname: recommendationRepository.fetchCachedNickname(),
            todayDiscoveries: loaded.0,
            trendingFeeds: loaded.1,
            preferenceGenreNovelState: loaded.2
        )
    }
}
