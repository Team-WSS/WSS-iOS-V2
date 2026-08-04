//
//  RecommendationRepository.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol RecommendationRepository {
    func fetchTodayDiscoveries() async throws(RepositoryError) -> [TodayDiscovery]
    func fetchTrendingFeeds() async throws(RepositoryError) -> [TrendingFeed]
    func fetchInterestFeeds() async throws(RepositoryError) -> InterestFeedState
    func fetchPreferenceGenreNovels() async throws(RepositoryError) -> PreferenceGenreNovelState
    func fetchSosoPick() async throws(RepositoryError) -> [SosoPick]

    /// 로컬에 캐시된 내 닉네임. 네트워크를 타지 않아 async·throws가 아니다(없으면 nil).
    func fetchCachedNickname() -> String?
}
