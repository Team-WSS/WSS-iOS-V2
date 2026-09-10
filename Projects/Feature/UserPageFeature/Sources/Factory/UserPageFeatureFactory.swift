//
//  UserPageFeatureFactory.swift
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
import CollectionDomain
import Logger

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 internal로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
public enum UserPageFeatureFactory {

    /// - Parameters:
    ///   - onRoute: 화면 전환 의도 콜백 — 목적지·payload는 `UserPageRoute`(Navigation/) 참고(#253,
    ///     `.feed`/`.novel`은 #255 QA로 추가).
    ///   - onUserBlocked: 차단 성공(이 화면 dismiss) 직전 → 차단한 상대 닉네임을 실어 올리는 콜백.
    ///     이 화면은 곧 pop되므로 "차단했어요" 토스트(`WSSToastType.blockUser(nickname:)`)는 복귀할
    ///     화면(App 조정 계층)이 띄운다 — 지금은 도관만 뚫어둔 seam이고 실제 표시 배선은 크로스스크린
    ///     완료 피드백 재설계 때 채운다(`docs/TODO.md` 12절).
    @MainActor
    public static func makeView(
        userID: UserID,
        loadProfileUseCase: LoadProfileUseCase,
        loadGenrePreferencesUseCase: LoadGenrePreferencesUseCase,
        loadNovelPreferencesUseCase: LoadNovelPreferencesUseCase,
        loadUserRegisteredNovelStatsUseCase: LoadUserRegisteredNovelStatsUseCase,
        loadCollectionPreviewsUseCase: LoadCollectionPreviewsUseCase,
        loadUserFeedsUseCase: LoadUserFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        blockUserUseCase: BlockUserUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        logger: Logger? = nil,
        onRoute: @escaping (UserPageRoute) -> Void,
        onUserBlocked: @escaping (String) -> Void = { _ in }
    ) -> some View {
        let viewModel = UserPageViewModel(
            userID: userID,
            loadProfileUseCase: loadProfileUseCase,
            loadGenrePreferencesUseCase: loadGenrePreferencesUseCase,
            loadNovelPreferencesUseCase: loadNovelPreferencesUseCase,
            loadUserRegisteredNovelStatsUseCase: loadUserRegisteredNovelStatsUseCase,
            loadCollectionPreviewsUseCase: loadCollectionPreviewsUseCase,
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
            onRoute: onRoute,
            onUserBlocked: onUserBlocked
        )
    }

    /// "활동" 탭 미리보기(최대 5개)에서 "전체보기"로 진입하는 전체 피드 목록(무한스크롤) 화면.
    /// 호출자(App)가 `makeView`의 `onFeedListTapped`를 받아 조립한다(#201부터 — `UserPageView`가
    /// 더 이상 로컬로 push하지 않는다).
    @MainActor
    public static func makeFeedListView(
        userID: UserID,
        nickname: String,
        profileImage: URL?,
        loadUserFeedsUseCase: LoadUserFeedsUseCase,
        feedLikeUseCase: FeedLikeUseCase,
        reportSpoilerFeedUseCase: ReportSpoilerFeedUseCase,
        reportImproperFeedUseCase: ReportImproperFeedUseCase,
        logger: Logger? = nil,
        onFeedTapped: @escaping (FeedID) -> Void = { _ in },
        onNovelTapped: @escaping (NovelID) -> Void = { _ in }
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
        return UserFeedListView(viewModel: viewModel, onFeedTapped: onFeedTapped, onNovelTapped: onNovelTapped)
    }
}
