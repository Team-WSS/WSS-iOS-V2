//
//  RecommendationAction.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 3/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Logger

public enum RecommendationAction {
    case fetchTodayDiscoveries
    case fetchTrendingFeeds
    case fetchInterestFeeds
    case fetchPreferenceGenreNovels
    case fetchSosoPick

    var name: String {
        switch self {
        case .fetchTodayDiscoveries:        "오늘의 발견 조회"
        case .fetchTrendingFeeds:           "지금 뜨는 글 조회"
        case .fetchInterestFeeds:           "관심 글 조회"
        case .fetchPreferenceGenreNovels:   "선호 장르 기반 소설 조회"
        case .fetchSosoPick:                "소소픽 조회"
        }
    }
}
