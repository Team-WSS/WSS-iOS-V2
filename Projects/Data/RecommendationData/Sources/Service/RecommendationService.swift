//
//  RecommendationService.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 3/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

public protocol RecommendationService {
    func getTodayDiscovery() async throws -> TodayDiscoveryNovelsResponse
    func getTrendingFeeds() async throws -> TrendingFeedsResponse
    func getInterestFeeds() async throws -> InterestFeedsResponse
    func getPreferenceGenreNovels() async throws -> PreferenceGenreNovelsResponse
    func getSosopickNovels() async throws -> SosopickNovelsResponse
}
