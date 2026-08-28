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
    ///   - onFeedListTapped: "활동기록 더보기" 탭 → 전체 피드 목록 진입 콜백. `(userID, nickname,
    ///     profileImage)`를 그대로 받아 호출자가 자기 `Destination`에 실어 push한다(#201) — 이 화면
    ///     자신이 이미 로드해둔 프로필 값이라 App이 따로 조회할 필요가 없다.
    ///   - onCollectionItemTapped: 컬렉션 미리보기 항목 탭 → 그 컬렉션 상세 진입 콜백.
    ///   - onCollectionListTapped: 컬렉션 섹션 헤더 탭(컬렉션이 있을 때) → 그 유저의 컬렉션 목록 진입 콜백.
    static func makeView(
        userID: UserID,
        dependencies: AppDependencies,
        onLibraryTapped: @escaping () -> Void = {},
        onFeedListTapped: @escaping (UserID, String, URL?) -> Void = { _, _, _ in },
        onCollectionItemTapped: @escaping (CollectionID) -> Void = { _ in },
        onCollectionListTapped: @escaping () -> Void = {}
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
            onLibraryTapped: onLibraryTapped,
            onFeedListTapped: onFeedListTapped,
            onCollectionItemTapped: onCollectionItemTapped,
            onCollectionListTapped: onCollectionListTapped
        )
    }

    /// "활동기록 더보기"로 진입하는 전체 피드 목록(`UserPageFeatureFactory.makeFeedListView`) 조립 —
    /// `onFeedListTapped`를 받은 탭 Root가 자기 `Destination`에서 이 메서드로 push한다.
    static func makeFeedListView(
        userID: UserID,
        nickname: String,
        profileImage: URL?,
        dependencies: AppDependencies
    ) -> some View {
        UserPageFeatureFactory.makeFeedListView(
            userID: userID,
            nickname: nickname,
            profileImage: profileImage,
            loadUserFeedsUseCase: DefaultLoadUserFeedsUseCase(feedRepository: dependencies.feedRepository),
            feedLikeUseCase: DefaultLikeUseCase(feedRepository: dependencies.feedRepository),
            reportSpoilerFeedUseCase: DefaultReportSpoilerFeedUseCase(repository: dependencies.socialRepository),
            reportImproperFeedUseCase: DefaultReportImproperFeedUseCase(repository: dependencies.socialRepository),
            logger: dependencies.logger
        )
    }
}
