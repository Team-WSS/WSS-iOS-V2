//
//  UserPageAnalyticsEvent.swift
//  UserPageFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Analytics

/// 마이페이지·타유저 프로필 화면이 공유하는 이벤트 이름 카탈로그(#249).
enum UserPageAnalyticsEvent: String, AnalyticsEvent {
    /// 마이페이지 화면 진입
    case mypageViewed = "mypage"
    /// 타유저 마이페이지 화면 진입
    case otherMypageViewed = "other_mypage"
    /// 타유저 차단 버튼 클릭
    case otherBlockTapped = "other_block"

    // MARK: - V2 신규(CSV에 없음)

    /// 활동 피드 좋아요 클릭
    case feedLikeTapped = "other_feed_like"
    /// 활동 피드 스포일러 신고
    case feedSpoilerReported = "other_feed_spoiler_report"
    /// 활동 피드 부적절한 표현 신고
    case feedAbuseReported = "other_feed_abuse_report"
    /// 컬렉션 섹션 탭(컬렉션 없는 유저 안내 토스트 포함)
    case collectionSectionTapped = "other_collection_section"
}
