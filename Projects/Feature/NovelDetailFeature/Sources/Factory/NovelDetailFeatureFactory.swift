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
    ///   - onRoute: 화면 전환 의도 콜백 — 목적지·payload는 `NovelDetailRoute`(Navigation/) 참고.
    ///     실제 화면 조립·push는 호출자(App 조정 계층)가 exhaustive switch로 수행한다(#253).
    ///   - onAuthenticationRequired: 인증 만료(세션 죽음) 시 로그인 화면 진입 콜백 — 화면 내 모든 서버 호출 공통.
    ///     화면 전환 "의도"가 아니라 세션 이벤트라 `onRoute`에 합치지 않는다.
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
        onboardingHintUseCase: OnboardingHintUseCase,
        logger: Logger? = nil,
        onRoute: @escaping (NovelDetailRoute) -> Void,
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
                onboardingHintUseCase: onboardingHintUseCase,
                logger: logger
            ),
            loadNotificationSettingUseCase: loadNotificationSettingUseCase,
            updateNotificationSettingUseCase: updateNotificationSettingUseCase,
            logger: logger,
            onRoute: onRoute,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
