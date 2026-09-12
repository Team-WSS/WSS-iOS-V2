//
//  FeedAnalyticsEvent.swift
//  FeedFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Analytics

/// 이 모듈(소소한수다 목록·피드 상세·글 작성) 전체가 공유하는 이벤트 이름 카탈로그(#249).
/// ⚠️ V1의 "소소한수다 > 장르탭"(`feed_R`/`feed_RF`/`feed_F`/`feed_HF`/`feed_MH`/`feed_BL`/`feed_D`/
/// `feed_M`/`feed_LN`/`feed_etc`, 10종)은 여기 없다 — V2 소소피드엔 장르 탭 UI 자체가 없다
/// (`SosoFeedOption`은 전체글/추천글 2종뿐, 장르 축이 없음). 억지로 "내 피드" 필터 시트의 장르
/// 체크박스에 갖다붙이지 않았다(다른 화면·다른 인터랙션이라 매핑이 아니라 오귀속이 된다) — 이슈 #249
/// 최종 보고에서 "대응 UI 없음"으로 별도 안내.
enum FeedAnalyticsEvent: String, AnalyticsEvent {
    /// 소소한수다 화면 진입
    case screenViewed = "feed_all"
    /// 글쓰기 플로팅 버튼 클릭
    case writeFloatingButtonTapped = "feed_write_floating_btn"
    /// 목록 셀 좋아요 클릭
    case likeTapped = "feed_like"
    /// 피드 상세보기 화면 진입
    case detailViewed = "feed_detail"
    /// 피드 상세 좋아요 클릭
    case detailLikeTapped = "feed_detail_like"
    /// 글 작성 뷰 진입
    case writeViewed = "write"
    /// 스포일러 토글 켜짐(백로그)
    case spoilerToggleOn = "write_spoiler_on"
    /// 스포일러 토글 꺼짐(백로그)
    case spoilerToggleOff = "write_spoiler_off"
    /// 작품 연결하기 시트 열기(백로그)
    case connectNovelSheetOpened = "write_connect_novel"
    /// 작품 연결 검색 결과 없을 때 문의하기 클릭
    case connectNovelContactTapped = "contact_novel_connect"
    /// 글 작성 완료
    case submitted = "write_feed"
    /// 댓글 작성(보내기) 클릭
    case commentSubmitted = "write_comment"
    /// 게시글 스포일러 신고
    case feedSpoilerReported = "alert_feed_spoiler"
    /// 게시글 부적절한 표현 신고
    case feedAbuseReported = "alert_feed_abuse"
    /// 댓글 스포일러 신고
    case commentSpoilerReported = "alert_comment_spoiler"
    /// 댓글 부적절한 표현 신고
    case commentAbuseReported = "alert_comment_abuse"

    // MARK: - V2 신규(CSV에 없음)

    /// 글 작성 이미지 추가
    case imageAdded = "write_image_add"
    /// 글 작성 이미지 삭제
    case imageRemoved = "write_image_remove"
    /// 글 작성 비공개 전환
    case privateOn = "write_private_on"
    /// 글 작성 공개 전환
    case privateOff = "write_private_off"
    /// 작품 연결 확정(검색 결과 선택 확정)
    case novelConnected = "write_connect_novel_confirm"
    /// 연결된 작품 해제
    case novelDisconnected = "write_connect_novel_remove"
    /// 피드 삭제 확정(목록·상세 공용)
    case feedDeleted = "feed_delete"
    /// 댓글 삭제 확정
    case commentDeleted = "write_comment_delete"
    /// 내 피드/소소피드 탭 전환
    case tabSelected = "feed_tab_select"
    /// 소소피드 옵션(전체글/추천글) 전환
    case sosoOptionSelected = "feed_soso_option_select"
    /// 내 피드 정렬 토글
    case myFeedSortToggled = "feed_myfeed_sort"
    /// 내 피드 필터 시트 "작품 찾기" 적용
    case myFeedFilterApplied = "feed_myfeed_filter_apply"
}
