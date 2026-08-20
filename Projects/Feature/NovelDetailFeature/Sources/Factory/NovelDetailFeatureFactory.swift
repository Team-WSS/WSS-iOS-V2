//
//  NovelDetailFeatureFactory.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import NotificationDomain
import NovelDomain
import NovelReviewDomain
import SocialDomain
import Logger

/// 소설 상세 화면의 유일한 public 진입점. opaque 반환 → View/VM은 internal 유지.
public enum NovelDetailFeatureFactory {

    /// - Parameters:
    ///   - onReviewTapped: 작품 평가 화면 진입 콜백. Feature 간 직접 의존 금지 —
    ///     실제 화면 전환(NovelReviewFeatureFactory 조립)은 호출자(App 조정 계층)가 수행한다.
    ///     `ReadingStatus`는 평가 초안에 seed할 읽기 상태(상태바에서 탭한 상태 / 평가 있음의 칩·여백 탭은 현재 상태).
    ///   - onCreateFeedTapped: 피드 작성(CreateFeed) 진입 콜백 — "나도 한마디"·피드 탭 플로팅 버튼 공용.
    ///   - onFeedTapped: 피드 상세 진입 콜백 — 피드 탭의 셀 탭.
    ///   - onUserProfileTapped: 유저 프로필 진입 콜백 — 피드 셀 프로필 영역(이미지+닉네임) 탭(내 글이면 호출되지 않음).
    ///   - onNovelTapped: 작품 상세 진입 콜백 — 피드 셀 연결 작품 배너 탭.
    ///   - onEditFeedTapped: 피드 수정 진입 콜백 — 내 글 threedots 드롭다운의 "수정하기". 대상 피드
    ///     `FeedID`만 넘긴다 — 실제 데이터 로드는 수정 화면 자신이 한다.
    ///   - onAuthorTapped: 작가 검색 화면 진입 콜백 — 헤더 작품 정보의 작가 이름 탭. 전달값은 탭한 작가 한 명의 이름.
    ///     실제 화면 전환은 호출자(App 조정 계층)가 수행한다.
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백 — 화면 내 모든 서버 호출 공통.
    ///     실제 화면 전환은 호출자(App 조정 계층)가 수행한다.
    @MainActor
    public static func makeView(
        novelID: NovelID,
        loadNovelUseCase: LoadNovelUseCase,
        novelInterestUseCase: NovelInterestUseCase,
        loadNovelFeedsUseCase: LoadNovelFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        deleteFeedUseCase: DeleteFeedUseCase,
        deleteNovelReviewUseCase: DeleteNovelReviewUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        loadNotificationSettingUseCase: LoadNovelNotificationSettingUseCase,
        updateNotificationSettingUseCase: UpdateNovelNotificationSettingUseCase,
        logger: Logger? = nil,
        onReviewTapped: @escaping (NovelInformation, ReadingStatus) -> Void,
        onCreateFeedTapped: @escaping () -> Void,
        onFeedTapped: @escaping (FeedID) -> Void,
        onUserProfileTapped: @escaping (UserID) -> Void,
        onNovelTapped: @escaping (NovelID) -> Void,
        onEditFeedTapped: @escaping (FeedID) -> Void,
        onAuthorTapped: @escaping (String) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        NovelDetailView(
            novelID: novelID,
            viewModel: NovelDetailViewModel(
                novelID: novelID,
                loadNovelUseCase: loadNovelUseCase,
                novelInterestUseCase: novelInterestUseCase,
                loadNovelFeedsUseCase: loadNovelFeedsUseCase,
                feedLikeUseCase: feedLikeUseCase,
                deleteFeedUseCase: deleteFeedUseCase,
                deleteNovelReviewUseCase: deleteNovelReviewUseCase,
                reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
                reportImproperFeedUseCase: reportImproperFeedUseCase,
                logger: logger
            ),
            loadNotificationSettingUseCase: loadNotificationSettingUseCase,
            updateNotificationSettingUseCase: updateNotificationSettingUseCase,
            logger: logger,
            onReviewTapped: onReviewTapped,
            onCreateFeedTapped: onCreateFeedTapped,
            onFeedTapped: onFeedTapped,
            onUserProfileTapped: onUserProfileTapped,
            onNovelTapped: onNovelTapped,
            onEditFeedTapped: onEditFeedTapped,
            onAuthorTapped: onAuthorTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
