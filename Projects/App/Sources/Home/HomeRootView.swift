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
import FeedDomain
import FeedFeature
import HomeFeature
import NotificationDomain
import NovelDomain
import ProfileDomain
import NotificationFeature
import PushAuthorization
import RecommendationDomain
import SearchDomain
import UserPageFeature
import WSSComponent

/// `MainTabView`의 "홈" 탭 콘텐츠 — `HomeFeatureFactory`가 반환하는 화면을 그대로 조립한다.
/// 작품 상세·피드 상세·일반 검색·작가 이름 검색·작품 평가·피드 작성·유저 프로필·알림 목록/상세까지는
/// 실제로 push한다. 그 안에서 다시 열리는 화면(상세탐색)은 아직 로그만 남기는 placeholder다.
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
        /// 타유저 프로필의 "활동기록 더보기" → 전체 피드 목록(#201, `UserPageAssembly.makeFeedListView`).
        case userFeedList(userID: UserID, nickname: String, profileImage: URL?)
        case search
        case authorSearch(String)
        case detailSearch(SearchFilter)
        case novelReview(novelID: NovelID, title: String, status: ReadingStatus)
        case notification
        case notificationDetail(NotificationID)
        /// 선호장르 미설정 유도 CTA → 마이페이지 편집(닉네임/캐릭터/장르 등을 한 화면에서 고치는 화면,
        /// 전용 "장르만" 편집 화면은 없다 — `MypageFeatureFactory.makeEditView` 재사용, 사용자 확정).
        case preferenceGenreSetting
    }

    let dependencies: AppDependencies
    /// 홈의 API 호출이 401(갱신 실패 포함)로 막히면 발화 — idempotent해야 한다(`HomeFeature/CLAUDE.md`).
    let onAuthenticationRequired: () -> Void

    @State private var path = NavigationPath()
    /// 알림 목록으로 이동한 뒤, 그 화면 위에 기기 설정 유도 알럿을 띄워야 하는지(#193) — `.overlay` 기반
    /// `showWSSAlert`가 push 전환과 동시에 뜨면 전환에 밀려 사라지므로(`HomeFeature/CLAUDE.md` 참고),
    /// `HomeFeature`가 아니라 여기(`NavigationStack` 컨테이너)에 붙여 push가 끝난 뒤에도 살아남게 한다.
    @State private var isPushAuthorizationAlertPresented = false
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
                onDetailSearchTapped: { dependencies.logger.info("상세탐색 진입(미구현)") },
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
                // 탭 콘텐츠에서 push된 화면은 탭바를 가린다 — 여기 한 곳에서 걸어두면 Destination
                // case가 늘어나도 매번 개별 뷰에 붙일 필요가 없다.
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
                            onFeedListTapped: { userID, nickname, profileImage in
                                path.append(Destination.userFeedList(userID: userID, nickname: nickname, profileImage: profileImage))
                            }
                        )
                    case .userFeedList(let userID, let nickname, let profileImage):
                        UserPageAssembly.makeFeedListView(
                            userID: userID,
                            nickname: nickname,
                            profileImage: profileImage,
                            dependencies: dependencies
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
                    case .preferenceGenreSetting:
                        mypageEditView
                    case .notification:
                        notificationListView
                    case .notificationDetail(let notificationID):
                        notificationDetailView(notificationID)
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
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

// MARK: - 피드 상세

private extension HomeRootView {
    func feedDetailView(_ feedID: FeedID) -> some View {
        FeedDetailAssembly.makeView(
            feedID: feedID,
            dependencies: dependencies,
            onNovelTapped: { path.append(Destination.novel($0)) },
            onEditFeedTapped: { path.append(Destination.editFeed($0)) }
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
            connectedNovel: connectedNovel
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
