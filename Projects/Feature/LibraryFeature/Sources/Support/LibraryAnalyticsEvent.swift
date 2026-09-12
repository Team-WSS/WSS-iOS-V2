//
//  LibraryAnalyticsEvent.swift
//  LibraryFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Analytics

/// 이 모듈(내 서재·타유저 서재) 전체가 공유하는 이벤트 이름 카탈로그.
enum LibraryAnalyticsEvent: String, AnalyticsEvent {
    /// 내 서재 화면 진입(첫 진입만 — 재진입 조용한 갱신은 제외)
    case screenViewed = "library_view"
    /// 우상단 등록 버튼 클릭
    case registerButtonTapped = "library_register_btn"
    /// 빈 상태 "웹소설 찾기" 클릭
    case emptySearchTapped = "library_empty_search_btn"
    /// "알림 관리" 클릭
    case notificationTapped = "library_notification_btn"
    /// 관심 칩 토글
    case interestFilterToggled = "library_interest_filter"
    /// 필터 시트 "작품 찾기" 적용
    case filterApplied = "library_filter_apply"
    /// 정렬 시트에서 정렬 선택
    case sortSelected = "library_sort"
    /// 작품 셀 클릭(그리드/리스트 공용)
    case novelSelected = "library_novel_select"
    /// 타유저 서재 화면 진입
    case userScreenViewed = "user_library_view"
    /// 타유저 서재 정렬 선택
    case userSortSelected = "user_library_sort"
    /// 타유저 서재 작품 셀 클릭
    case userNovelSelected = "user_library_novel_select"
}
