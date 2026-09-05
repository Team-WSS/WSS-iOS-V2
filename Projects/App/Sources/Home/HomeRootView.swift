//
//  HomeRootView.swift
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
import HomeFeature
import LibraryFeature
import NotificationDomain
import NovelDomain
import ProfileDomain
import NotificationFeature
import PushAuthorization
import RecommendationDomain
import SearchDomain
import SearchFeature
import UserPageFeature
import WSSComponent

/// `MainTabView`의 "홈" 탭 콘텐츠 — `HomeFeatureFactory`가 반환하는 화면을 그대로 조립한다.
/// 작품 상세·피드 상세·일반 검색·작가 이름 검색·작품 평가·피드 작성·유저 프로필·그 프로필의 타유저
/// 서재·알림 목록/상세·상세탐색 필터/결과까지 실제로 push한다.
struct HomeRootView: View {

    /// `NovelID`/`FeedID`가 둘 다 `IDWrapper<Int>`라 타입이 같아 `NavigationPath`에 그냥 섞어 넣으면
    /// `.navigationDestination(for:)`가 어느 쪽인지 구분을 못 한다 — 래퍼 enum으로 명시적으로 태깅한다.
    private enum Destination: Hashable {
        case novel(NovelID)
        case feed(FeedID)
        /// 홈 탭엔 피드 작성 진입점(연필 아이콘 등)이 따로 없어 작품 상세發("나도 한마디") 경로 하나뿐 —
        /// `FeedRootView`처럼 옵션 없는 `createFeed` 케이스를 따로 둘 필요가 없다.
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
        /// 같은 3케이스를 둔다(조립은 `CollectionEditAssembly`). 진입 선택 스냅샷은 반드시 path payload로
        /// 실어 보낸다(`App/CLAUDE.md`의 스크래치 `@State` 레이스 주의사항).
        case editCollection(CollectionID)
        case searchNovelForCollection([CollectionNovel])
        case myLibrarySelectForCollection([CollectionNovel])
        case search
        case authorSearch(String)
        /// "뭐 읽을지 고민될 때?" 배너(정보 탭)·일반 검색의 장르/키워드 "더보기" 헤더(#236, 진입점이
        /// 열 탭을 payload로 지정) → 상세탐색 필터 화면. 확정("작품 찾기") 시 이 화면 자신은 pop되지
        /// 않고 그대로 스택에 남아, 그 위로 `detailSearch(filter)`가 push된다
        /// (`SearchFeature/CLAUDE.md`의 "필터 화면 진입·복귀" 참고 — pop/push 여부는 항상 호출부 책임).
        case detailSearchFilter(DetailSearchFilterTab)
        case detailSearch(SearchFilter)
        case novelReview(novelID: NovelID, title: String, status: ReadingStatus)
        case notification
        case notificationDetail(NotificationID)
        /// 선호장르 미설정 유도 CTA → 마이페이지 편집(닉네임/캐릭터/장르 등을 한 화면에서 고치는 화면,
        /// 전용 "장르만" 편집 화면은 없다 — `MypageFeatureFactory.makeEditView` 재사용, 사용자 확정).
        case preferenceGenreSetting
    }

    let dependencies: AppDependencies
    /// 앱 밖에서 들어온 딥링크(#228) — `MainTabView`가 이 탭이 선택돼 있을 때만 값을 준다. 받으면 스택
    /// 위에 push하고 `onDeepLinkConsumed`로 돌려준다(아래 `.onChange(initial:)` — mount 전에 도착한
    /// 링크도 잡는다).
    let deepLink: DeepLink?
    let onDeepLinkConsumed: () -> Void
    /// 딥링크로 push한 화면이 스택에서 빠지면(뒤로가기·pop) 발화 — `MainTabView`가 401 복원 창을 닫는다(#228).
    let onDeepLinkDestinationDismissed: () -> Void
    /// 홈의 API 호출이 401(갱신 실패 포함)로 막히면 발화 — idempotent해야 한다(`HomeFeature/CLAUDE.md`).
    let onAuthenticationRequired: () -> Void

    @State private var path = NavigationPath()
    /// 딥링크 화면이 놓인 스택 깊이 — `path.count`가 이보다 작아지면 그 화면이 빠진 것(아래 `.onChange(of: path.count)`).
    @State private var deepLinkDestinationDepth: Int?
    /// 크로스스크린 완료 피드백(#236) — push된 화면이 pop되며 남긴 완료("차단했어요"·"작성 완료!"·
    /// "평가 완료!")를 복귀 화면 위 토스트로 알린다(`CrossScreenFeedback.swift` 참고, 4탭 공통).
    @State private var crossScreenFeedback = CrossScreenFeedbackState()
    /// 알림 목록으로 이동한 뒤, 그 화면 위에 기기 설정 유도 알럿을 띄워야 하는지(#193) — `.overlay` 기반
    /// `showWSSAlert`가 push 전환과 동시에 뜨면 전환에 밀려 사라지므로(`HomeFeature/CLAUDE.md` 참고),
    /// `HomeFeature`가 아니라 여기(`NavigationStack` 컨테이너)에 붙여 push가 끝난 뒤에도 살아남게 한다.
    @State private var isPushAuthorizationAlertPresented = false
    /// "작품 추가"/"서재에서 추가" 확정 결과를 컬렉션 수정 화면에 돌려주는 1회성 nil→값 채널(#228,
    /// `MypageRootView`와 동일 — 확정(return) 값이라 `Destination` 레이스 대상이 아니다).
    @State private var pendingCollectionNovelSelection: [CollectionNovel]?
    /// "설정하러 가기" 탭 시 iOS 설정 앱의 이 앱 알림 설정 페이지로 바로 연다.
    @Environment(\.openURL) private var openURL

    /// 로그인 직후 `syncUserBasicInfo()`가 채워두는 로컬 캐시(`FeedDetailAssembly.currentUserID`와 동일
    /// 출처) — 내 프로필로의 "타유저 프로필" 진입을 막는 라우팅 가드에 쓴다.
    private var currentUserID: UserID? {
        UserDefaultsStorage().get(.userID).map(UserID.init)
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeFeatureFactory.makeView(
                loadHomeDataUseCase: DefaultLoadHomeDataUseCase(repository: dependencies.recommendationRepository),
                loadUnreadNotificationStatusUseCase: DefaultLoadUnreadNotificationStatusUseCase(
                    repository: dependencies.notificationRepository
                ),
                pushAuthorizationChecker: DefaultPushAuthorizationChecker(),
                logger: dependencies.logger,
                onNovelSelected: { path.append(Destination.novel($0)) },
                onFeedSelected: { path.append(Destination.feed($0)) },
                onSearchTapped: { path.append(Destination.search) },
                onDetailSearchTapped: { path.append(Destination.detailSearchFilter(.info)) },
                onNotificationTapped: {
                    path.append(Destination.notification)
                    Task {
                        if await DefaultPushAuthorizationChecker().authorizationStatus() == .denied {
                            isPushAuthorizationAlertPresented = true
                        }
                    }
                },
                onPreferenceGenreSettingTapped: { path.append(Destination.preferenceGenreSetting) },
                onAuthenticationRequired: onAuthenticationRequired
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Destination.self) { destination in
                Group {
                    switch destination {
                    case .novel(let novelID):
                        novelDetailView(novelID)
                    case .feed(let feedID):
                        feedDetailView(feedID)
                    case .createFeedFromNovel(let connectedNovel):
                        createFeedView(connectedNovel: connectedNovel)
                    case .editFeed(let feedID):
                        FeedDetailAssembly.makeEditFeedView(
                            feedID: feedID,
                            dependencies: dependencies,
                            onSubmitted: { crossScreenFeedback.present(.feedEdited) }
                        )
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
                            onUserBlocked: { crossScreenFeedback.present(.userBlocked(nickname: $0)) }
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
                    case .detailSearchFilter(let initialTab):
                        detailSearchFilterView(initialTab: initialTab)
                    case .detailSearch(let filter):
                        detailSearchResultView(filter)
                    case .novelReview(let novelID, let title, let status):
                        NovelReviewAssembly.makeView(
                            novelID: novelID,
                            title: title,
                            status: status,
                            dependencies: dependencies,
                            onAuthenticationRequired: onAuthenticationRequired,
                            onSaved: { crossScreenFeedback.present(.novelReviewed) }
                        )
                    case .preferenceGenreSetting:
                        mypageEditView
                    case .notification:
                        notificationListView
                    case .notificationDetail(let notificationID):
                        notificationDetailView(notificationID)
                    }
                }
            }
        }
        .hidesTabBar(when: !path.isEmpty)
        .showWSSAlert(
            isPresented: $isPushAuthorizationAlertPresented,
            type: .setAppNotification,
            buttonActions: [
                { isPushAuthorizationAlertPresented = false },  // "다음에 하기"
                {
                    isPushAuthorizationAlertPresented = false
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }  // "설정하러 가기"
            ]
        )
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
        .showCrossScreenFeedbackToast($crossScreenFeedback)
    }
}

// MARK: - 작품 상세

private extension HomeRootView {
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

// MARK: - 컬렉션 수정 (#228 — 딥링크로 "내" 컬렉션이 이 탭 위에 열릴 수 있어 4탭 공통. 조립은
// `CollectionEditAssembly`, pop 핸들러만 이 Root가 갖는다 — `MypageRootView`와 동일 구조)

private extension HomeRootView {
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

// MARK: - 타유저 서재 (타유저 프로필의 서재 블록 탭)

private extension HomeRootView {
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

// MARK: - 피드 상세

private extension HomeRootView {
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

private extension HomeRootView {
    /// 이 탭엔 `.createFeedFromNovel` 하나뿐이라 `connectedNovel`은 항상 값이 있다.
    func createFeedView(connectedNovel: ConnectedNovel) -> some View {
        FeedFeatureFactory.makeCreateFeedView(
            createFeedUseCase: DefaultCreateFeedUseCase(repository: dependencies.feedRepository),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository),
            appReviewUseCase: DefaultAppReviewRequestUseCase(repository: dependencies.appReviewRequestRepository),
            connectedNovel: connectedNovel,
            onSubmitted: {
                crossScreenFeedback.present(.feedEdited)
                // 피드 탭 목록은 재진입에 목록을 다시 받지 않아, 다른 탭에서 쓴 새 글은 이 신호로만 들어간다.
                dependencies.feedListInvalidation.markFeedCreated()
            }
        )
    }
}

// MARK: - 일반 검색

private extension HomeRootView {
    /// `.search`(우상단 검색 아이콘, 빈 검색창)와 `.authorSearch`(작가 이름 탭, 사전 검색된 결과) 둘 다
    /// 이 화면을 그대로 재사용한다 — 차이는 `initialQuery` 유무뿐.
    func searchView(initialQuery: String? = nil) -> some View {
        SearchAssembly.makeView(
            dependencies: dependencies,
            onNovelSelected: { path.append(Destination.novel($0)) },
            onDetailSearchRequested: { path.append(Destination.detailSearch($0)) },
            onDetailSearchFilterRequested: { path.append(Destination.detailSearchFilter($0)) },
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

// MARK: - 상세탐색 필터 ("뭐 읽을지 고민될 때?" 배너 + 일반 검색의 "더보기" 헤더 — 3탭 공용이 되어
// #236에서 SearchAssembly로 승격, 키워드 탭 콘텐츠 조립도 그쪽으로 옮겼다)

private extension HomeRootView {
    func detailSearchFilterView(initialTab: DetailSearchFilterTab) -> some View {
        SearchAssembly.makeDetailSearchFilterView(
            initialTab: initialTab,
            dependencies: dependencies,
            onSearch: { filter in path.append(Destination.detailSearch(filter)) }
        )
    }
}

// MARK: - 알림 목록/상세

private extension HomeRootView {
    var notificationListView: some View {
        NotificationFeatureFactory.makeNotificationListView(
            loadPagedNotificationsUseCase: DefaultLoadPagedNotificationsUseCase(repository: dependencies.notificationRepository),
            markNotificationAsReadUseCase: DefaultMarkNotificationAsReadUseCase(repository: dependencies.notificationRepository),
            logger: dependencies.logger,
            onNotificationSelected: { path.append(Destination.notificationDetail($0)) },
            onFeedSelected: { path.append(Destination.feed($0)) },
            onNovelSelected: { path.append(Destination.novel($0)) },
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    func notificationDetailView(_ notificationID: NotificationID) -> some View {
        NotificationFeatureFactory.makeNotificationDetailView(
            notificationID: notificationID,
            loadNotificationDetailUseCase: DefaultLoadNotificationDetailUseCase(repository: dependencies.notificationRepository),
            logger: dependencies.logger,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}

// MARK: - 마이페이지 편집 (선호장르 설정 유도 CTA 진입점)

private extension HomeRootView {
    var mypageEditView: some View {
        MypageFeatureFactory.makeEditView(
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
