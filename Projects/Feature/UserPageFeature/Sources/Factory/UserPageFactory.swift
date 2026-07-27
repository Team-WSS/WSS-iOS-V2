//
//  UserPageFactory.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import ProfileDomain
import NovelDomain
import FeedDomain
import SocialDomain
import Logger

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 internal로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
public enum UserPageFactory {

    @MainActor
    public static func makeView(
        userID: UserID,
        loadProfileUseCase: LoadProfileUseCase,
        loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase,
        loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase,
        loadUserRegisteredNovelStatsUseCase: LoadUserRegisteredNovelStatsUseCase,
        loadUserFeedsUseCase: LoadUserFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        blockUserUseCase: BlockUserUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        logger: Logger? = nil
    ) -> some View {
        let viewModel = UserPageViewModel(
            userID: userID,
            loadProfileUseCase: loadProfileUseCase,
            loadGenrePreferencesUseCase: loadGenrePreferencesUseCase,
            loadNovelPreferencesUseCase: loadNovelPreferencesUseCase,
            loadUserRegisteredNovelStatsUseCase: loadUserRegisteredNovelStatsUseCase,
            loadUserFeedsUseCase: loadUserFeedsUseCase,
            feedLikeUseCase: feedLikeUseCase,
            blockUserUseCase: blockUserUseCase,
            reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
            reportImproperFeedUseCase: reportImproperFeedUseCase,
            logger: logger
        )
        return UserPageView(
            viewModel: viewModel,
            userID: userID,
            loadUserFeedsUseCase: loadUserFeedsUseCase,
            feedLikeUseCase: feedLikeUseCase,
            reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
            reportImproperFeedUseCase: reportImproperFeedUseCase,
            logger: logger
        )
    }

    /// "활동" 탭 미리보기(최대 5개)에서 "전체보기"로 진입하는 전체 피드 목록(무한스크롤) 화면.
    /// `UserPageView`의 내부 네비게이션이 직접 호출한다(`SettingFactory`의 다중 `makeXxxView`와 동일 패턴).
    @MainActor
    public static func makeFeedListView(
        userID: UserID,
        nickname: String,
        profileImage: URL?,
        loadUserFeedsUseCase: LoadUserFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        logger: Logger? = nil
    ) -> some View {
        let viewModel = UserFeedListViewModel(
            userID: userID,
            nickname: nickname,
            profileImage: profileImage,
            loadUserFeedsUseCase: loadUserFeedsUseCase,
            feedLikeUseCase: feedLikeUseCase,
            reportSpoilerFeedUseCase: reportSpoilerFeedUseCase,
            reportImproperFeedUseCase: reportImproperFeedUseCase,
            logger: logger
        )
        return UserFeedListView(viewModel: viewModel)
    }
}
