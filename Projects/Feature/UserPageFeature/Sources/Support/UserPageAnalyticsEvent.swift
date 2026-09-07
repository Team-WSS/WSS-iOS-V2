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
}
