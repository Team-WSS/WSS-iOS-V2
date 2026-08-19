//
//  FeedDetailAssembly.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseData
import BaseDomain
import CommentDomain
import FeedDomain
import FeedFeature
import ProfileDomain
import SocialDomain

/// 피드 상세(`FeedFeatureFactory.makeFeedDetailView`) 조립 — 홈/피드/서재 세 탭이 전부 같은 방식으로
/// push해서(#196) 공용으로 뽑았다. `onNovelTapped`만 호출자별로 다르다(각 탭 Root가 자기 `Destination`
/// enum에 맞게 push해야 해서).
@MainActor
enum FeedDetailAssembly {
    /// 로그인한 본인 글인지(수정/삭제 노출) 판단용. 로그인 직후 `syncUserBasicInfo()`가 채워두는 로컬
    /// 캐시를 그대로 읽는다(`OnboardingRootView.syncProfileThenFinish` 참고) — 별도 서버 호출 없음.
    private static var currentUserID: Int? {
        UserDefaultsStorage().get(.userID)
    }

    static func makeView(
        feedID: FeedID,
        dependencies: AppDependencies,
        onNovelTapped: @escaping (NovelID) -> Void
    ) -> some View {
        FeedFeatureFactory.makeFeedDetailView(
            feedID: feedID,
            currentUserID: currentUserID,
            loadFeedDetailUseCase: DefaultLoadFeedUseCase(feedRepository: dependencies.feedRepository),
            feedLikeUseCase: DefaultLikeUseCase(feedRepository: dependencies.feedRepository),
            deleteFeedUseCase: DefaultDeleteFeedUseCase(repository: dependencies.feedRepository),
            loadCommentsUseCase: DefaultLoadCommentsUseCase(repository: dependencies.commentRepository),
            createCommentUseCase: DefaultCreateCommentUseCase(repository: dependencies.commentRepository),
            deleteCommentUseCase: DefaultDeleteCommentUseCase(repository: dependencies.commentRepository),
            editCommentUseCase: DefaultEditCommentUseCase(repository: dependencies.commentRepository),
            reportSpoilerFeedUseCase: DefaultReportSpoilerFeedUseCase(repository: dependencies.socialRepository),
            reportImproperFeedUseCase: DefaultReportImproperFeedUseCase(repository: dependencies.socialRepository),
            reportSpoilerCommentUseCase: DefaultReportSpoilerCommentUseCase(repository: dependencies.socialRepository),
            reportImproperCommentUseCase: DefaultReportImproperCommentUseCase(repository: dependencies.socialRepository),
            loadProfileUseCase: DefaultLoadProfileUseCase(profileRepository: dependencies.profileRepository),
            logger: dependencies.logger,
            onNovelTapped: onNovelTapped
        )
    }
}
