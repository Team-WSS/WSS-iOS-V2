//
//  HomeRootView.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import HomeFeature
import NotificationDomain
import NovelDomain
import ProfileDomain
import RecommendationDomain
import SearchDomain
import UserPageFeature

/// `MainTabView`의 "홈" 탭 콘텐츠 — `HomeFactory`가 반환하는 화면을 그대로 조립한다.
/// 작품 상세·피드 상세·일반 검색까지는 실제로 push한다. 그 안에서 다시 열리는 화면(작품 평가·피드
/// 작성/수정·유저 프로필·작가 검색·알림 목록·선호장르 설정)은 대상 Feature가 아직 App에 안 붙어
/// 로그만 남기는 placeholder다.
struct HomeRootView: View {

    /// `NovelID`/`FeedID`가 둘 다 `IDWrapper<Int>`라 타입이 같아 `NavigationPath`에 그냥 섞어 넣으면
    /// `.navigationDestination(for:)`가 어느 쪽인지 구분을 못 한다 — 래퍼 enum으로 명시적으로 태깅한다.
    private enum Destination: Hashable {
        case novel(NovelID)
        case feed(FeedID)
        case search
        case detailSearch(SearchFilter)
        /// 선호장르 미설정 유도 CTA → 마이페이지 편집(닉네임/캐릭터/장르 등을 한 화면에서 고치는 화면,
        /// 전용 "장르만" 편집 화면은 없다 — `MypageFactory.makeEditView` 재사용, 사용자 확정).
        case preferenceGenreSetting
    }

    let dependencies: AppDependencies
    /// 홈의 API 호출이 401(갱신 실패 포함)로 막히면 발화 — idempotent해야 한다(`HomeFeature/CLAUDE.md`).
    let onAuthenticationRequired: () -> Void

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeFactory.makeView(
                loadHomeDataUseCase: DefaultLoadHomeDataUseCase(repository: dependencies.recommendationRepository),
                loadUnreadNotificationStatusUseCase: DefaultLoadUnreadNotificationStatusUseCase(
                    repository: dependencies.notificationRepository
                ),
                logger: dependencies.logger,
                onNovelSelected: { path.append(Destination.novel($0)) },
                onFeedSelected: { path.append(Destination.feed($0)) },
                onSearchTapped: { path.append(Destination.search) },
                onDetailSearchTapped: { dependencies.logger.info("상세탐색 진입(미구현)") },
                onNotificationTapped: { dependencies.logger.info("알림 목록 진입(미구현)") },
                onPreferenceGenreSettingTapped: { path.append(Destination.preferenceGenreSetting) },
                onAuthenticationRequired: onAuthenticationRequired
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Destination.self) { destination in
                // 탭 콘텐츠에서 push된 화면은 탭바를 가린다 — 여기 한 곳에서 걸어두면 Destination
                // case가 늘어나도 매번 개별 뷰에 붙일 필요가 없다.
                Group {
                    switch destination {
                    case .novel(let novelID):
                        novelDetailView(novelID)
                    case .feed(let feedID):
                        feedDetailView(feedID)
                    case .search:
                        searchView
                    case .detailSearch(let filter):
                        detailSearchResultView(filter)
                    case .preferenceGenreSetting:
                        mypageEditView
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
    }
}

// MARK: - 작품 상세

private extension HomeRootView {
    func novelDetailView(_ novelID: NovelID) -> some View {
        NovelDetailAssembly.makeView(
            novelID: novelID,
            dependencies: dependencies,
            onFeedTapped: { path.append(Destination.feed($0)) },
            onNovelTapped: { path.append(Destination.novel($0)) },
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}

// MARK: - 피드 상세

private extension HomeRootView {
    func feedDetailView(_ feedID: FeedID) -> some View {
        FeedDetailAssembly.makeView(
            feedID: feedID,
            dependencies: dependencies,
            onNovelTapped: { path.append(Destination.novel($0)) }
        )
    }
}

// MARK: - 일반 검색

private extension HomeRootView {
    var searchView: some View {
        SearchAssembly.makeView(
            dependencies: dependencies,
            onNovelSelected: { path.append(Destination.novel($0)) },
            onDetailSearchRequested: { path.append(Destination.detailSearch($0)) }
        )
    }

    func detailSearchResultView(_ filter: SearchFilter) -> some View {
        SearchAssembly.makeDetailSearchResultView(
            filter: filter,
            dependencies: dependencies,
            onNovelSelected: { path.append(Destination.novel($0)) }
        )
    }
}

// MARK: - 마이페이지 편집 (선호장르 설정 유도 CTA 진입점)

private extension HomeRootView {
    var mypageEditView: some View {
        MypageFactory.makeEditView(
            loadInitialProfileUseCase: DefaultLoadProfileDraftUseCase(profileRepository: dependencies.profileRepository),
            loadProfileCharacterUseCase: DefaultLoadProfileCharacterUseCase(profileRepository: dependencies.profileRepository),
            validateNicknameUseCase: DefaultValidateNicknameUseCase(repository: dependencies.profileRepository),
            updateProfileUseCase: DefaultUpdateProfileUseCase(profileRepository: dependencies.profileRepository),
            // `MyPageEditView`가 저장 성공 시 스스로 `dismiss()`한다 — 여기서 또 `path.removeLast()`를
            // 부르면 이중 pop이 된다(App/CLAUDE.md 참고).
            onSaved: {},
            logger: dependencies.logger
        )
    }
}
