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
@MainActor
enum NovelDetailAssembly {
    static func makeView(
        novelID: NovelID,
        dependencies: AppDependencies,
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
            feedLikeUseCase: DefaultLikeUseCase(feedRepository: dependencies.feedRepository),
            deleteFeedUseCase: DefaultDeleteFeedUseCase(repository: dependencies.feedRepository),
            deleteNovelReviewUseCase: DefaultDeleteNovelReviewUseCase(repository: dependencies.novelReviewRepository),
            reportSpoilerFeedUseCase: DefaultReportSpoilerFeedUseCase(repository: dependencies.socialRepository),
            reportImproperFeedUseCase: DefaultReportImproperFeedUseCase(repository: dependencies.socialRepository),
            loadNotificationSettingUseCase: DefaultLoadNovelNotificationSettingUseCase(repository: dependencies.novelNotificationRepository),
            updateNotificationSettingUseCase: DefaultUpdateNovelNotificationSettingUseCase(repository: dependencies.novelNotificationRepository),
            onboardingHintUseCase: DefaultOnboardingHintUseCase(repository: dependencies.onboardingHintRepository),
            logger: dependencies.logger,
            onRoute: onRoute,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
