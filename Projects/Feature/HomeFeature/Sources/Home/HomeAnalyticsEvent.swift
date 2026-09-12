//
//  HomeAnalyticsEvent.swift
//  HomeFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Analytics

/// 홈 화면 이벤트 이름 카탈로그(#249). 원본 이벤트 리스트(엠플리튜드)의 이름을 그대로 rawValue로 둔다.
enum HomeAnalyticsEvent: String, AnalyticsEvent {
    /// 홈 화면 진입
    case screenViewed = "home"
    /// 탐색 서치바 클릭(검색 화면 진입)
    case searchBarTapped = "general_search"
    /// "내 취향에 맞는 웹소설 찾기" 배너 클릭(상세탐색 진입)
    case detailSearchBannerTapped = "seek"
    /// 오늘의 발견 카드 클릭
    case todayDiscoverySelected = "home_today_ranking"
    /// 추천글(지금 뜨는 수다글) 카드 클릭
    case trendingFeedSelected = "home_hot_feedlist"
    /// "이 웹소설은 어때요?" 그리드 작품 클릭
    case preferenceGenreNovelSelected = "home_prefer_novellist"
    /// 선호 장르 설정 유도 버튼 클릭
    case preferenceGenreSettingTapped = "home_to_prefer_btn"
}
