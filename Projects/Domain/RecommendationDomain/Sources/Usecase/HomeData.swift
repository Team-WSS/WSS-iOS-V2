//
//  HomeData.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct HomeData {
    public let todayDiscoveries: [TodayDiscovery]
    public let trendingFeeds: [TrendingFeed]
    public let interestFeedState: InterestFeedState
    public let preferenceGenreNovelState: PreferenceGenreNovelState
}
