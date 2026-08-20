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
import SearchDomain
import SocialDomain

/// 피드 상세(`FeedFeatureFactory.makeFeedDetailView`) 조립 — 홈/피드/서재 세 탭이 전부 같은 방식으로
/// push해서(#196) 공용으로 뽑았다. `onNovelTapped`만 호출자별로 다르다(각 탭 Root가 자기 `Destination`
/// enum에 맞게 push해야 해서). 내 글 "수정" 드롭다운도 `makeEditFeedView`로 여기서 같이 조립한다 —
/// 수정 화면 자신이 `feedID`로 대상 피드를 불러오므로(#197) App은 UseCase만 물리면 된다.
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
        onNovelTapped: @escaping (NovelID) -> Void,
        onEditFeedTapped: @escaping (FeedID) -> Void = { _ in }
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
            onNovelTapped: onNovelTapped,
            onEditFeedTapped: onEditFeedTapped
        )
    }

    /// `feedID`만 받아 수정 화면(`makeEditFeedView`)을 조립한다 — 대상 피드 로드는 그 화면 자신이 하므로
    /// App은 UseCase만 물리면 된다(#197, 빠른 화면 전환 우선 — 이전 화면에서 미리 준비해두지 않는다).
    static func makeEditFeedView(
        feedID: FeedID,
        dependencies: AppDependencies
    ) -> some View {
        FeedFeatureFactory.makeEditFeedView(
            feedID: feedID,
            editFeedUseCase: DefaultEditFeedUseCase(repository: dependencies.feedRepository),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository),
            loadFeedDetailUseCase: DefaultLoadFeedUseCase(feedRepository: dependencies.feedRepository)
        )
    }
}
