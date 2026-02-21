//
//  RecommendationRepository.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol RecommendationRepository {
    func fetchTodayDiscoveries() async throws -> [TodayDiscovery]
    func fetchTrendingFeeds() async throws -> [TrendingFeed]
    func fetchInterestFeeds() async throws -> InterestFeedState
    func fetchRecommendedNovels() async throws -> RecommendedNovelState
    func fetchSosoPick() async throws -> [SosoPick]
}
