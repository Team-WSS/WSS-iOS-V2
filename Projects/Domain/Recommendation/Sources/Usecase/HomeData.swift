//
//  HomeData.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct HomeData {
    public let todayDiscoveries: Result<[TodayDiscovery], Error>
    public let trendingFeeds: Result<[TrendingFeed], Error>
    public let interestFeedState: Result<InterestFeedState, Error>
    public let recommendedNovelState: Result<RecommendedNovelState, Error>
}
