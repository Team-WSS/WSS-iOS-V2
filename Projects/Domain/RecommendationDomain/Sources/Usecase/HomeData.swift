//
//  HomeData.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct HomeData {
    /// 로컬에 캐시된 내 닉네임. 서버 응답이 아니라 로그인·프로필 저장 시 남겨둔 값이라
    /// 아직 없으면 nil이다(호출자가 닉네임 없는 표기를 정한다).
    public let nickname: String?
    public let todayDiscoveries: [TodayDiscovery]
    public let trendingFeeds: [TrendingFeed]
    public let preferenceGenreNovelState: PreferenceGenreNovelState

    public init(
        nickname: String?,
        todayDiscoveries: [TodayDiscovery],
        trendingFeeds: [TrendingFeed],
        preferenceGenreNovelState: PreferenceGenreNovelState
    ) {
        self.nickname = nickname
        self.todayDiscoveries = todayDiscoveries
        self.trendingFeeds = trendingFeeds
        self.preferenceGenreNovelState = preferenceGenreNovelState
    }
}
