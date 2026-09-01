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
import WSSComponent

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
        /// 컬렉션 수정 트리(#228) — 딥링크로 "내" 컬렉션 상세가 이 탭 위에 열릴 수 있어 `MypageRootView`와
        /// 같은 3케이스를 둔다(조립은 `CollectionEditAssembly`). 진입 선택 스냅샷은 반드시 path payload로.
        case editCollection(CollectionID)
        case searchNovelForCollection([CollectionNovel])
        case myLibrarySelectForCollection([CollectionNovel])
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
    /// 앱 밖에서 들어온 딥링크(#228) — `MainTabView`가 이 탭이 선택돼 있을 때만 값을 준다. 받으면 스택
    /// 위에 push하고 `onDeepLinkConsumed`로 돌려준다(`HomeRootView`와 동일 규칙).
    let deepLink: DeepLink?
    let onDeepLinkConsumed: () -> Void
    /// 딥링크로 push한 화면이 스택에서 빠지면 발화(`HomeRootView`와 동일 규칙).
    let onDeepLinkDestinationDismissed: () -> Void
    let onAuthenticationRequired: () -> Void

    @State private var path = NavigationPath()
    @State private var deepLinkDestinationDepth: Int?
    /// "작품 추가"/"서재에서 추가" 확정 결과를 컬렉션 수정 화면에 돌려주는 1회성 nil→값 채널(#228,
    /// `MypageRootView`와 동일 — 확정(return) 값이라 `Destination` 레이스 대상이 아니다).
    @State private var pendingCollectionNovelSelection: [CollectionNovel]?
    /// 타유저 프로필 차단 성공 시(그 화면 pop) 복귀 화면 위에 띄우는 "차단했어요" 토스트(#221, V1 parity).
    /// `UserPageAssembly`의 `onUserBlocked` seam이 닉네임을 올려주면 이 루트가 표시한다 — 4탭 공통
    /// 패턴이라 통합 채널 전환은 App 배선 재설계 때 재검토(`docs/TODO.md` 12절 크로스스크린 완료 피드백).
    @State private var isUserBlockedToastPresented = false
    @State private var blockedNickname = ""

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
                loadMyLibraryFilterUseCase: DefaultLoadMyLibraryFilterUseCase(
                    repository: dependencies.myLibraryFilterRepository
                ),
                saveMyLibraryFilterUseCase: DefaultSaveMyLibraryFilterUseCase(
                    repository: dependencies.myLibraryFilterRepository
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
                            onCollectionListTapped: { path.append(Destination.collectionList(userID)) },
                            onUserBlocked: { nickname in
                                blockedNickname = nickname
                                isUserBlockedToastPresented = true
                            }
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
                            onNovelTapped: { path.append(Destination.novel($0)) },
                            onEditTapped: { path.append(Destination.editCollection(id)) }
                        )
                    case .collectionList(let userID):
                        CollectionListAssembly.makeView(
                            userID: userID,
                            dependencies: dependencies,
                            onAuthenticationRequired: onAuthenticationRequired,
                            onCollectionSelected: { path.append(Destination.collectionDetail($0)) }
                        )
                    case .editCollection(let id):
                        editCollectionView(id: id)
                    case .searchNovelForCollection(let initialSelection):
                        collectionSearchNovelView(initialSelection: initialSelection)
                    case .myLibrarySelectForCollection(let initialSelection):
                        collectionMyLibrarySelectView(initialSelection: initialSelection)
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
        .onChange(of: deepLink, initial: true) { _, deepLink in
            guard let deepLink else { return }
            switch deepLink {
            case .collectionDetail(let id):
                path.append(Destination.collectionDetail(id))
            }
            deepLinkDestinationDepth = path.count
            onDeepLinkConsumed()
        }
        .onChange(of: path.count) { _, count in
            guard let depth = deepLinkDestinationDepth, count < depth else { return }
            deepLinkDestinationDepth = nil
            onDeepLinkDestinationDismissed()
        }
        .showWSSToast(isPresented: $isUserBlockedToastPresented, type: .blockUser(nickname: blockedNickname))
    }
}

// MARK: - 컬렉션 수정 (#228 — 딥링크로 "내" 컬렉션이 이 탭 위에 열릴 수 있어 4탭 공통. 조립은
// `CollectionEditAssembly`, pop 핸들러만 이 Root가 갖는다 — `MypageRootView`와 동일 구조)

private extension LibraryRootView {
    func editCollectionView(id: CollectionID) -> some View {
        CollectionEditAssembly.makeEditView(
            id: id,
            dependencies: dependencies,
            pendingNovelSelection: $pendingCollectionNovelSelection,
            onAddNovelTapped: handleCollectionAddNovelTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    func collectionSearchNovelView(initialSelection: [CollectionNovel]) -> some View {
        CollectionEditAssembly.makeSearchNovelView(
            initialSelection: initialSelection,
            dependencies: dependencies,
            onConfirm: handleCollectionSearchNovelConfirm,
            onLibrarySelectTapped: handleCollectionLibrarySelectTapped,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    func collectionMyLibrarySelectView(initialSelection: [CollectionNovel]) -> some View {
        CollectionEditAssembly.makeMyLibrarySelectView(
            initialSelection: initialSelection,
            dependencies: dependencies,
            onConfirm: handleCollectionLibrarySelectConfirm,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// "작품 추가" 타일 탭 → 검색 화면으로 push. 현재 선택을 path payload로 그대로 실어 보낸다.
    func handleCollectionAddNovelTapped(_ currentSelection: [CollectionNovel]) {
        path.append(Destination.searchNovelForCollection(currentSelection))
    }

    /// 검색 화면의 "완료" 확정 → 수정 화면까지 1단계 pop, 결과는 `pendingCollectionNovelSelection`으로.
    func handleCollectionSearchNovelConfirm(_ novels: [CollectionNovel]) {
        pendingCollectionNovelSelection = novels
        path.removeLast(1)
    }

    /// 검색 화면의 "서재에서 추가" 탭 → 서재 선택 화면으로 push.
    func handleCollectionLibrarySelectTapped(_ currentSelection: [CollectionNovel]) {
        path.append(Destination.myLibrarySelectForCollection(currentSelection))
    }

    /// 서재 선택 화면의 "추가" 확정 → 수정 화면까지 2단계 pop(`CollectionFeature/CLAUDE.md` "2단계 pop" 정본).
    func handleCollectionLibrarySelectConfirm(_ novels: [CollectionNovel]) {
        pendingCollectionNovelSelection = novels
        path.removeLast(2)
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
            appReviewUseCase: DefaultAppReviewRequestUseCase(repository: dependencies.appReviewRequestRepository),
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
