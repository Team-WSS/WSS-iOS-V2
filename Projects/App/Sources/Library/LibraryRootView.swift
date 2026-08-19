//
//  LibraryRootView.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import LibraryFeature
import NotificationDomain
import NovelDomain
import SearchDomain
import SettingFeature

/// "서재" 탭 콘텐츠. 로그인한 본인 서재(`makeMyLibraryView`)만 붙인다 — 타유저 서재(`makeUserLibraryView`)는
/// 유저 프로필 화면에서 push되는 용도라 여기서 조립할 대상이 아니다. 작품 상세(`NovelDetailAssembly`)·
/// 일반 검색(`SearchAssembly`, "웹소설 찾기"·"작품 등록" 버튼 공용 — 서재는 별도 작품 등록 화면이 없고
/// 검색해서 작품을 찾아 상세에서 등록하는 흐름, 사용자 확정)·알림 설정(`SettingFactory.makeNotificationSettingView`,
/// 서재 알림 관리는 설정 목록 전체가 아니라 이 화면으로 바로 진입한다)까지 push한다.
struct LibraryRootView: View {

    private enum Destination: Hashable {
        case novel(NovelID)
        case feed(FeedID)
        case search
        case detailSearch(SearchFilter)
        case notificationSetting
    }

    let dependencies: AppDependencies
    let onAuthenticationRequired: () -> Void

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            LibraryFactory.makeMyLibraryView(
                loadMyLibraryUseCase: DefaultLoadMyLibraryUseCase(
                    novelRepository: dependencies.novelRepository,
                    keywordRepository: dependencies.keywordRepository
                ),
                loadMyLibraryKeywordsUseCase: DefaultLoadMyLibraryKeywordsUseCase(
                    novelRepository: dependencies.novelRepository
                ),
                logger: dependencies.logger,
                onNovelSelected: { path.append(Destination.novel($0)) },
                onSearchTapped: { path.append(Destination.search) },
                onRegisterTapped: { path.append(Destination.search) },
                onNotificationTapped: { path.append(Destination.notificationSetting) },
                onAuthenticationRequired: onAuthenticationRequired
            )
            .navigationDestination(for: Destination.self) { destination in
                // 탭 콘텐츠에서 push된 화면은 탭바를 가린다(`HomeRootView`와 동일 규칙).
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
                    case .notificationSetting:
                        notificationSettingView
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
    }
}

// MARK: - 작품 상세

private extension LibraryRootView {
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

// MARK: - 피드 상세 (작품 상세의 피드 탭)

private extension LibraryRootView {
    func feedDetailView(_ feedID: FeedID) -> some View {
        FeedDetailAssembly.makeView(
            feedID: feedID,
            dependencies: dependencies,
            onNovelTapped: { path.append(Destination.novel($0)) }
        )
    }
}

// MARK: - 일반 검색 (웹소설 찾기 / 작품 등록 공용)

private extension LibraryRootView {
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

// MARK: - 알림 설정

private extension LibraryRootView {
    var notificationSettingView: some View {
        SettingFactory.makeNotificationSettingView(
            loadPushPreferenceUseCase: DefaultLoadPushPreferenceUseCase(repository: dependencies.pushSettingRepository),
            updatePushPreferenceUseCase: DefaultUpdatePushPreferenceUseCase(repository: dependencies.pushSettingRepository),
            logger: dependencies.logger
        )
    }
}
