//
//  NovelDetailAssembly.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import NotificationDomain
import NovelDetailFeature
import NovelDomain
import NovelReviewDomain
import SocialDomain

/// 작품 상세(`NovelDetailFeatureFactory`) 조립 — 홈/피드/서재 세 탭이 전부 같은 방식으로 push해서(#196) 공용으로
/// 뽑았다. 화면 전환은 `onRoute`(`NovelDetailRoute` exhaustive switch, #253) 하나로 받고,
/// `onAuthenticationRequired`와 함께 호출자별로 다르다(각 탭 Root가 자기 `Destination` enum에 맞게
/// push하거나 자기 인증만료 콜백을 넘겨야 해서).
///
/// `needsFeedReloadForCreatedFeed`(#256)는 **일부러 기본값을 두지 않는다** — 이 화면발 피드 작성
/// (`.createFeedFromNovel`) 성공 복귀 시 피드 섹션을 리셋하는 신호인데, 4탭 전부가 그 작성 경로를 가져
/// 기본값이 있으면 새 탭/기존 탭이 배선을 빼먹어도 컴파일이 통과한다(작성 `onSubmitted` 기본값을 안 두는
/// 것과 같은 이유 — #236 리뷰). 각 탭 Root 로컬 `@State`의 Binding을 넘기고, 그 탭의 `.createFeedFromNovel`
/// `onSubmitted`에서 켠다.
@MainActor
enum NovelDetailAssembly {
    static func makeView(
        novelID: NovelID,
        dependencies: AppDependencies,
        needsFeedReloadForCreatedFeed: Binding<Bool>,
        onRoute: @escaping (NovelDetailRoute) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        NovelDetailFeatureFactory.makeView(
            novelID: novelID,
            loadNovelUseCase: DefaultLoadNovelUseCase(
                novelRepository: dependencies.novelRepository,
                keywordRepository: dependencies.keywordRepository
            ),
            novelInterestUseCase: DefaultNovelInterestUseCase(novelRepository: dependencies.novelRepository),
            loadNovelFeedsUseCase: DefaultLoadNovelFeedsUseCase(feedRepository: dependencies.feedRepository),
            loadFeedDetailUseCase: DefaultLoadFeedUseCase(feedRepository: dependencies.feedRepository),
            feedLikeUseCase: DefaultLikeUseCase(feedRepository: dependencies.feedRepository),
            deleteFeedUseCase: DefaultDeleteFeedUseCase(repository: dependencies.feedRepository),
            deleteNovelReviewUseCase: DefaultDeleteNovelReviewUseCase(repository: dependencies.novelReviewRepository),
            reportSpoilerFeedUseCase: DefaultReportSpoilerFeedUseCase(repository: dependencies.socialRepository),
            reportImproperFeedUseCase: DefaultReportImproperFeedUseCase(repository: dependencies.socialRepository),
            loadNotificationSettingUseCase: DefaultLoadNovelNotificationSettingUseCase(repository: dependencies.novelNotificationRepository),
            updateNotificationSettingUseCase: DefaultUpdateNovelNotificationSettingUseCase(repository: dependencies.novelNotificationRepository),
            onboardingHintUseCase: DefaultOnboardingHintUseCase(repository: dependencies.onboardingHintRepository),
            logger: dependencies.logger,
            needsFeedReloadForCreatedFeed: needsFeedReloadForCreatedFeed,
            onRoute: onRoute,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
