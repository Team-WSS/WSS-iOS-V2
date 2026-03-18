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
    func fetchRecommendedNovels() async throws(RepositoryError) -> RecommendedNovelState
    func fetchSosoPick() async throws(RepositoryError) -> [SosoPick]
}
