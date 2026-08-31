//
//  HomePrefetchStore.swift
//  RecommendationDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 홈 첫 로드용 single-shot 프리페치 저장고 (#225).
///
/// 런치 부트스트랩이 슬롯을 한 번 채우고(fill), 홈의 첫 로드가 한 번 소비하면(consume) 슬롯이 비워진다.
/// **TTL 캐시가 아니다** — 홈은 "탭 복귀마다 갱신" 계약이라, 소비 이후의 모든 로드는 네트워크로 가야 한다.
/// App DI가 단일 인스턴스를 만들어 채우는 쪽(SplashData)과 소비하는 쪽(RecommendationData)에 함께 주입한다.
public actor HomePrefetchStore {

    private var todayDiscoveries: [TodayDiscovery]?
    private var trendingFeeds: [TrendingFeed]?

    public init() {}

    public func fillTodayDiscoveries(_ discoveries: [TodayDiscovery]) {
        todayDiscoveries = discoveries
    }

    public func fillTrendingFeeds(_ feeds: [TrendingFeed]) {
        trendingFeeds = feeds
    }

    public func consumeTodayDiscoveries() -> [TodayDiscovery]? {
        defer { todayDiscoveries = nil }
        return todayDiscoveries
    }

    public func consumeTrendingFeeds() -> [TrendingFeed]? {
        defer { trendingFeeds = nil }
        return trendingFeeds
    }
}
