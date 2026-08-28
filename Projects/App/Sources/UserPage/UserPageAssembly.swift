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
    static func makeView(
        userID: UserID,
        dependencies: AppDependencies,
        onLibraryTapped: @escaping () -> Void = {}
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
            onLibraryTapped: onLibraryTapped
        )
    }
}
