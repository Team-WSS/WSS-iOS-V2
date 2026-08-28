//
//  LibraryRootView.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseData
import BaseDomain
import CollectionDomain
import FeedDomain
import FeedFeature
import LibraryFeature
import NotificationDomain
import NovelDomain
import SearchDomain
import SettingFeature

/// "서재" 탭 콘텐츠. 로그인한 본인 서재(`makeMyLibraryView`)를 붙이고, 이 탭에서 push되는 타유저
/// 프로필의 서재 블록 탭 시 그 유저의 서재(`makeUserLibraryView`)까지 다른 3탭과 동일하게 push한다
/// (#197 후속, 2026-08-28 — 4탭 전부 `UserPageAssembly.onLibraryTapped`를 연결하기로 확정). 작품 상세(`NovelDetailAssembly`)·
/// 일반 검색(`SearchAssembly`, "웹소설 찾기"·"작품 등록" 버튼 공용 — 서재는 별도 작품 등록 화면이 없고
/// 검색해서 작품을 찾아 상세에서 등록하는 흐름, 사용자 확정)·알림 설정(`SettingFeatureFactory.makeNotificationSettingView`,
/// 서재 알림 관리는 설정 목록 전체가 아니라 이 화면으로 바로 진입한다), 그리고 작품 상세에서 열리는
/// 작품 평가·피드 작성·유저 프로필까지 push한다.
struct LibraryRootView: View {

    private enum Destination: Hashable {
        case novel(NovelID)
        case feed(FeedID)
        /// 서재 탭엔 피드 작성 진입점(연필 아이콘 등)이 따로 없어 작품 상세發("나도 한마디") 경로 하나뿐 —
        /// `FeedRootView`처럼 옵션 없는 `createFeed` 케이스를 따로 둘 필요가 없다(`HomeRootView`와 동일).
        case createFeedFromNovel(ConnectedNovel)
        case editFeed(FeedID)
        case userPage(UserID)
        case userLibrary(UserID)
        /// 타유저 프로필의 "활동기록 더보기" → 전체 피드 목록(#201, `UserPageAssembly.makeFeedListView`).
        case userFeedList(userID: UserID, nickname: String, profileImage: URL?)
        /// 타유저 프로필의 컬렉션 미리보기 항목 탭 → 그 컬렉션 상세(`CollectionDetailAssembly`).
        case collectionDetail(CollectionID)
        /// 타유저 프로필의 컬렉션 섹션 헤더 탭 → 그 유저의 컬렉션 목록(`CollectionListAssembly`,
        /// "내 컬렉션" 탭만 보이는 모드).
        case collectionList(UserID)
        case search
        case authorSearch(String)
        case detailSearch(SearchFilter)
        case novelReview(novelID: NovelID, title: String, status: ReadingStatus)
        case notificationSetting
        // 알림 설정의 완결/휴재복귀 알림 목록(#201부터 이 루트가 직접 조립 — `SettingFeatureFactory`의
        // 다중 `makeXxxView`와 동일하게 App이 화면 전환을 조립한다).
        case completionNotificationList
        case hiatusReturnNotificationList
    }

    let dependencies: AppDependencies
    let onAuthenticationRequired: () -> Void

    @State private var path = NavigationPath()

    /// 로그인 직후 `syncUserBasicInfo()`가 채워두는 로컬 캐시(`FeedDetailAssembly.currentUserID`와 동일
    /// 출처) — 내 프로필로의 "타유저 프로필" 진입을 막는 라우팅 가드에 쓴다.
    private var currentUserID: UserID? {
        UserDefaultsStorage().get(.userID).map(UserID.init)
    }

    var body: some View {
        NavigationStack(path: $path) {
            LibraryFeatureFactory.makeMyLibraryView(
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
                    case .createFeedFromNovel(let connectedNovel):
                        createFeedView(connectedNovel: connectedNovel)
                    case .editFeed(let feedID):
                        FeedDetailAssembly.makeEditFeedView(feedID: feedID, dependencies: dependencies)
                    case .userPage(let userID):
                        UserPageAssembly.makeView(
                            userID: userID,
                            dependencies: dependencies,
                            onLibraryTapped: { path.append(Destination.userLibrary(userID)) },
                            onFeedListTapped: { userID, nickname, profileImage in
                                path.append(Destination.userFeedList(userID: userID, nickname: nickname, profileImage: profileImage))
                            },
                            onCollectionItemTapped: { path.append(Destination.collectionDetail($0)) },
                            onCollectionListTapped: { path.append(Destination.collectionList(userID)) }
                        )
                    case .userLibrary(let userID):
                        userLibraryView(userID)
                    case .userFeedList(let userID, let nickname, let profileImage):
                        UserPageAssembly.makeFeedListView(
                            userID: userID,
                            nickname: nickname,
                            profileImage: profileImage,
                            dependencies: dependencies
                        )
                    case .collectionDetail(let id):
                        CollectionDetailAssembly.makeView(
                            id: id,
                            dependencies: dependencies,
                            onAuthenticationRequired: onAuthenticationRequired,
                            onNovelTapped: { path.append(Destination.novel($0)) }
                        )
                    case .collectionList(let userID):
                        CollectionListAssembly.makeView(
                            userID: userID,
                            dependencies: dependencies,
                            onAuthenticationRequired: onAuthenticationRequired,
                            onCollectionSelected: { path.append(Destination.collectionDetail($0)) }
                        )
                    case .search:
                        searchView()
                    case .authorSearch(let authorName):
                        searchView(initialQuery: authorName)
                    case .detailSearch(let filter):
                        detailSearchResultView(filter)
                    case .novelReview(let novelID, let title, let status):
                        NovelReviewAssembly.makeView(
                            novelID: novelID,
                            title: title,
                            status: status,
                            dependencies: dependencies,
                            onAuthenticationRequired: onAuthenticationRequired
                        )
                    case .notificationSetting:
                        notificationSettingView
                    case .completionNotificationList:
                        completionNotificationListView
                    case .hiatusReturnNotificationList:
                        hiatusReturnNotificationListView
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
            onReviewTapped: { information, status in
                path.append(Destination.novelReview(novelID: information.novel.id, title: information.novel.title, status: status))
            },
            onCreateFeedTapped: { path.append(Destination.createFeedFromNovel($0)) },
            onFeedTapped: { path.append(Destination.feed($0)) },
            onUserProfileTapped: {
                // 피드 탭 셀의 프로필 탭과 같은 이중 가드(#196) — 내 프로필로는 절대 안 간다.
                guard $0 != currentUserID else { return }
                path.append(Destination.userPage($0))
            },
            onNovelTapped: { path.append(Destination.novel($0)) },
            onEditFeedTapped: { path.append(Destination.editFeed($0)) },
            onAuthorTapped: { path.append(Destination.authorSearch($0)) },
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}

// MARK: - 타유저 서재 (타유저 프로필의 서재 블록 탭)

private extension LibraryRootView {
    func userLibraryView(_ userID: UserID) -> some View {
        LibraryFeatureFactory.makeUserLibraryView(
            userID: userID,
            loadUserLibraryUseCase: DefaultLoadUserLibraryUseCase(
                novelRepository: dependencies.novelRepository,
                keywordRepository: dependencies.keywordRepository
            ),
            logger: dependencies.logger,
            onNovelSelected: { path.append(Destination.novel($0)) },
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
            onNovelTapped: { path.append(Destination.novel($0)) },
            onEditFeedTapped: { path.append(Destination.editFeed($0)) },
            onUserProfileTapped: {
                // 피드 탭 셀의 프로필 탭과 같은 이중 가드(#196) — 내 프로필로는 절대 안 간다.
                guard $0 != currentUserID else { return }
                path.append(Destination.userPage($0))
            }
        )
    }
}

// MARK: - 피드 작성 (작품 상세 "나도 한마디")

private extension LibraryRootView {
    /// 이 탭엔 `.createFeedFromNovel` 하나뿐이라 `connectedNovel`은 항상 값이 있다.
    func createFeedView(connectedNovel: ConnectedNovel) -> some View {
        FeedFeatureFactory.makeCreateFeedView(
            createFeedUseCase: DefaultCreateFeedUseCase(repository: dependencies.feedRepository),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository),
            connectedNovel: connectedNovel
        )
    }
}

// MARK: - 일반 검색 (웹소설 찾기 / 작품 등록 공용)

private extension LibraryRootView {
    /// `.search`(웹소설 찾기/작품 등록, 빈 검색창)와 `.authorSearch`(작가 이름 탭, 사전 검색된 결과) 둘 다
    /// 이 화면을 그대로 재사용한다 — 차이는 `initialQuery` 유무뿐.
    func searchView(initialQuery: String? = nil) -> some View {
        SearchAssembly.makeView(
            dependencies: dependencies,
            onNovelSelected: { path.append(Destination.novel($0)) },
            onDetailSearchRequested: { path.append(Destination.detailSearch($0)) },
            initialQuery: initialQuery
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
        SettingFeatureFactory.makeNotificationSettingView(
            loadPushPreferenceUseCase: DefaultLoadPushPreferenceUseCase(repository: dependencies.pushSettingRepository),
            updatePushPreferenceUseCase: DefaultUpdatePushPreferenceUseCase(repository: dependencies.pushSettingRepository),
            logger: dependencies.logger,
            onCompletionListTapped: { path.append(Destination.completionNotificationList) },
            onHiatusReturnListTapped: { path.append(Destination.hiatusReturnNotificationList) }
        )
    }

    var completionNotificationListView: some View {
        SettingFeatureFactory.makeCompletionNotificationListView(
            loadNovelNotificationSubscriptionsUseCase: DefaultLoadNovelNotificationSubscriptionsUseCase(
                repository: dependencies.novelNotificationRepository
            ),
            deleteNovelNotificationSubscriptionsUseCase: DefaultDeleteNovelNotificationSubscriptionsUseCase(
                repository: dependencies.novelNotificationRepository
            ),
            logger: dependencies.logger,
            onBrowseNovels: { path.append(Destination.search) }
        )
    }

    var hiatusReturnNotificationListView: some View {
        SettingFeatureFactory.makeHiatusReturnNotificationListView(
            loadNovelNotificationSubscriptionsUseCase: DefaultLoadNovelNotificationSubscriptionsUseCase(
                repository: dependencies.novelNotificationRepository
            ),
            deleteNovelNotificationSubscriptionsUseCase: DefaultDeleteNovelNotificationSubscriptionsUseCase(
                repository: dependencies.novelNotificationRepository
            ),
            logger: dependencies.logger,
            onBrowseNovels: { path.append(Destination.search) }
        )
    }
}
