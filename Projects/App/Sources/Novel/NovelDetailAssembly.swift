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
import NovelDetailFeature
import NovelDomain
import NovelReviewDomain
import SocialDomain

/// 작품 상세(`NovelDetailFactory`) 조립 — 홈/피드/서재 세 탭이 전부 같은 방식으로 push해서(#196) 공용으로
/// 뽑았다. `onFeedTapped`/`onNovelTapped`/`onEditFeedTapped`/`onAuthorTapped`/`onAuthenticationRequired`만
/// 호출자별로 다르다(각 탭 Root가 자기 `Destination` enum에 맞게 push하거나 자기 인증만료 콜백을 넘겨야
/// 해서) — 나머지(작품 평가·피드 작성·유저 프로필)는 대상 Feature가 아직 App에 안 붙어 세 탭 모두 동일한 placeholder다.
@MainActor
enum NovelDetailAssembly {
    static func makeView(
        novelID: NovelID,
        dependencies: AppDependencies,
        onFeedTapped: @escaping (FeedID) -> Void,
        onNovelTapped: @escaping (NovelID) -> Void,
        onEditFeedTapped: @escaping (FeedID) -> Void,
        onAuthorTapped: @escaping (String) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        NovelDetailFactory.makeView(
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
            logger: dependencies.logger,
            onReviewTapped: { _, _ in dependencies.logger.info("작품 평가 진입(미구현)") },
            onCreateFeedTapped: { dependencies.logger.info("피드 작성 진입(미구현)") },
            onFeedTapped: onFeedTapped,
            onUserProfileTapped: { dependencies.logger.info("유저 프로필 진입(미구현): \($0)") },
            onNovelTapped: onNovelTapped,
            onEditFeedTapped: onEditFeedTapped,
            onAuthorTapped: onAuthorTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
