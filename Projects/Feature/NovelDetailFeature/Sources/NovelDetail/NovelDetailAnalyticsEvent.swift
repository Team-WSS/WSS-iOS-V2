//
//  NovelDetailAnalyticsEvent.swift
//  NovelDetailFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Analytics

/// 작품 상세 화면 이벤트 이름 카탈로그(#249).
enum NovelDetailAnalyticsEvent: String, AnalyticsEvent {
    /// 정보 탭 진입
    case infoTabViewed = "novel_info"
    /// 더보기 드롭다운 "오류 제보" 클릭
    case errorReportTapped = "contact_error"
    /// "작품 보러가기" 플랫폼 링크 클릭
    case platformLinkTapped = "direct_novel"
    /// 수다(피드) 탭 진입
    case feedTabViewed = "novel_feed"
    /// "나도 한마디" 버튼 클릭
    case writeButtonTapped = "novel_write_btn"
    /// 수다 탭 글쓰기 플로팅 버튼 클릭
    case writeFloatingButtonTapped = "novel_write_floating_btn"
    /// 작품 수다 좋아요 클릭(백로그)
    case feedLikeTapped = "novel_feed_like"
    /// 관심(♥) 클릭
    case interestToggled = "rate_love"
    /// 더보기 드롭다운 "평가 삭제" 클릭
    case reviewDeleteTapped = "rate_delete"
}
