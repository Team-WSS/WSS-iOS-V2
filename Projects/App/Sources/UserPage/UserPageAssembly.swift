//
//  UserPageAssembly.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import CollectionDomain
import FeedDomain
import NovelDomain
import ProfileDomain
import SocialDomain
import UserPageFeature

/// 타유저 프로필(`UserPageFeatureFactory.makeView`) 조립 — 어느 탭에서 프로필 이미지를 탭해도 같은 방식으로
/// push하도록 공용으로 뽑았다(`FeedDetailAssembly`/`NovelDetailAssembly`와 같은 이유, #196).
@MainActor
enum UserPageAssembly {
    /// - Parameters:
    ///   - onRoute: 화면 전환 의도 콜백 — 목적지·payload는 `UserPageRoute`(Navigation/) 참고(#253,
    ///     `.feed`/`.novel`은 #255 QA로 추가). `.userFeedList`는 이 화면이 이미 로드해둔 프로필 값을
    ///     실어 보내 App이 따로 조회할 필요가 없다.
    ///   - onUserBlocked: 차단 성공(이 화면 dismiss) 직전 → 차단한 상대 닉네임을 실어 올리는 콜백.
    ///     "차단했어요" 토스트(`WSSToastType.blockUser(nickname:)`)는 복귀할 탭 Root가 pop 후 띄운다 —
    ///     지금은 seam만 뚫어둔 상태로 각 탭 Root는 기본 no-op을 그대로 쓴다(크로스스크린 완료 피드백
    ///     재설계 때 `feedEdited`·`novelReviewed`와 함께 실제 표시를 배선, `docs/TODO.md` 12절).
    static func makeView(
        userID: UserID,
        dependencies: AppDependencies,
        onRoute: @escaping (UserPageRoute) -> Void,
        onUserBlocked: @escaping (String) -> Void = { _ in }
    ) -> some View {
        UserPageFeatureFactory.makeView(
            userID: userID,
            loadProfileUseCase: DefaultLoadProfileUseCase(profileRepository: dependencies.profileRepository),
            loadGenrePreferencesUseCase: DefaultLoadGenrePreferencesUseCase(
                profileRepository: dependencies.profileRepository
            ),
            loadNovelPreferencesUseCase: DefaultLoadNovelPreferencesUseCase(
                profileRepository: dependencies.profileRepository,
                keywordRepository: dependencies.keywordRepository
            ),
            loadUserRegisteredNovelStatsUseCase: DefaultLoadUserRegisteredNovelStatsUseCase(
                novelRepository: dependencies.novelRepository
            ),
            loadCollectionPreviewsUseCase: DefaultLoadCollectionPreviewsUseCase(
                collectionRepository: dependencies.collectionRepository
            ),
            loadUserFeedsUseCase: DefaultLoadUserFeedsUseCase(feedRepository: dependencies.feedRepository),
            feedLikeUseCase: DefaultLikeUseCase(feedRepository: dependencies.feedRepository),
            blockUserUseCase: DefaultBlockUserUseCase(repository: dependencies.socialRepository),
            reportSpoilerFeedUseCase: DefaultReportSpoilerFeedUseCase(repository: dependencies.socialRepository),
            reportImproperFeedUseCase: DefaultReportImproperFeedUseCase(repository: dependencies.socialRepository),
            logger: dependencies.logger,
            onRoute: onRoute,
            onUserBlocked: onUserBlocked
        )
    }

    /// "활동기록 더보기"로 진입하는 전체 피드 목록(`UserPageFeatureFactory.makeFeedListView`) 조립 —
    /// `UserPageRoute.userFeedList`를 받은 탭 Root가 자기 `Destination`에서 이 메서드로 push한다.
    static func makeFeedListView(
        userID: UserID,
        nickname: String,
        profileImage: URL?,
        dependencies: AppDependencies,
        onFeedTapped: @escaping (FeedID) -> Void = { _ in },
        onNovelTapped: @escaping (NovelID) -> Void = { _ in }
    ) -> some View {
        UserPageFeatureFactory.makeFeedListView(
            userID: userID,
            nickname: nickname,
            profileImage: profileImage,
            loadUserFeedsUseCase: DefaultLoadUserFeedsUseCase(feedRepository: dependencies.feedRepository),
            feedLikeUseCase: DefaultLikeUseCase(feedRepository: dependencies.feedRepository),
            reportSpoilerFeedUseCase: DefaultReportSpoilerFeedUseCase(repository: dependencies.socialRepository),
            reportImproperFeedUseCase: DefaultReportImproperFeedUseCase(repository: dependencies.socialRepository),
            logger: dependencies.logger,
            onFeedTapped: onFeedTapped,
            onNovelTapped: onNovelTapped
        )
    }
}
