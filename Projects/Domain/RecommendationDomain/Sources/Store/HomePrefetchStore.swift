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
///
/// 소비 창(window)은 **첫 소비 시도까지만** 열려 있다 — 빈 슬롯을 소비하려 한 경우에도 닫힌다.
/// 프리페치는 fire-and-forget이라 홈 첫 로드보다 늦게 착지할 수 있는데, 창을 닫지 않으면 그 값이
/// 남아 있다가 **다음 탭 복귀 갱신에서 소비돼** 런치 시점 데이터가 뒤늦게 화면에 뜬다(#225 리뷰).
public actor HomePrefetchStore {

    /// 슬롯 하나. 창이 닫힌 뒤 도착한 fill은 조용히 버린다.
    private struct Slot<Value: Sendable>: Sendable {
        private var value: Value?
        private var isClosed = false

        mutating func fill(_ newValue: Value) {
            guard !isClosed else { return }
            value = newValue
        }

        mutating func consume() -> Value? {
            defer {
                value = nil
                isClosed = true
            }
            return value
        }
    }

    private var todayDiscoveries = Slot<[TodayDiscovery]>()
    private var trendingFeeds = Slot<[TrendingFeed]>()

    public init() {}

    public func fillTodayDiscoveries(_ discoveries: [TodayDiscovery]) {
        todayDiscoveries.fill(discoveries)
    }

    public func fillTrendingFeeds(_ feeds: [TrendingFeed]) {
        trendingFeeds.fill(feeds)
    }

    public func consumeTodayDiscoveries() -> [TodayDiscovery]? {
        todayDiscoveries.consume()
    }

    public func consumeTrendingFeeds() -> [TrendingFeed]? {
        trendingFeeds.consume()
    }
}
