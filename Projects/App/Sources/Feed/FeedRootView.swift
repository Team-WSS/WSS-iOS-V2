//
//  FeedRootView.swift
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
import NovelDomain
import ProfileDomain
import SearchDomain
import SearchFeature
import SocialDomain
import WSSComponent

/// "피드" 탭 콘텐츠. `FeedFeatureFactory.makeSosoFeedView`(전체/내 피드)를 붙이고, 셀 탭 시 피드 상세,
/// 피드 셀·피드 상세 "수정" 드롭다운 탭 시 피드 수정(`FeedDetailAssembly.makeEditFeedView`), 우상단 연필
/// 아이콘 탭 시 피드 작성, 작성자 프로필 탭 시 타유저 프로필(`UserPageAssembly`), 연결 작품 배너 탭 시
/// 작품 상세, 그 타유저 프로필의 서재 블록 탭 시 타유저 서재(`LibraryFeatureFactory.makeUserLibraryView`), 작품
/// 상세 헤더의 작가 이름 탭 시 그 작가로 사전 검색된 결과 화면(`SearchAssembly.makeView(initialQuery:)`),
/// 작품 상세의 평가 상태바 탭 시 작품 평가(`NovelReviewAssembly`), "나도 한마디"/피드 탭 플로팅 버튼 탭
/// 시 그 작품이 미리 연결된 피드 작성(`createFeedFromNovel`, 연필 아이콘의 `createFeed`와 화면은 같이
/// 쓰되 케이스는 분리 — 아래 주의), 작성자 프로필 탭 시 타유저 프로필(이 화면 자신의 기존 케이스
/// 재사용)까지 push한다.
///
/// ⚠️ **`makeSosoFeedView` 자체는 `onAuthenticationRequired`를 안 받는다** — 그 콜백을 아예 몰라서
/// 소소피드/내 피드 로드가 401로 막히면 로그인 라우팅 대신 탭 콘텐츠 자리의 실패 뷰("일시적 오류",
/// 2026-09-10부터 — 그 전엔 조용한 빈 상태)로 흡수된다(Feature/CLAUDE.md의 "인증 만료 처리 계약"이
/// 이 화면엔 아직 안 들어와 있음, App 쪽에서 고칠 수 있는 부분이 아니라 FeedFeature 쪽 후속 작업).
/// 다만 여기서 push하는 **작품 상세(`NovelDetailFactory`)는 그 콜백을 받으므로**, 그
/// 안에서 발생하는 인증 만료는 정상적으로 처리하도록 `onAuthenticationRequired`를 받아 전달한다.
struct FeedRootView: View {

    /// `NovelID`/`FeedID`가 둘 다 `IDWrapper<Int>`라 타입이 같다 — `HomeRootView.Destination`과 같은
    /// 이유로 래퍼 enum이 필요하다(`App/CLAUDE.md` 참고).
    private enum Destination: Hashable {
        case feed(FeedID)
        case novel(NovelID)
        /// 공지 푸시 딥링크(`view=notificationDetail`, #243) → 알림 상세. 딥링크는 선택된 탭 위에 열려서
        /// 4탭 전부 이 목적지를 갖는다(`NotificationDetailAssembly`). 이 탭엔 알림 목록이 없어 딥링크 전용이다.
        case notificationDetail(NotificationID)
        case createFeed
        /// "나도 한마디"/피드 탭 플로팅 버튼 전용 — 작품 상세에서만 발생하는 흔치 않은 경로라
        /// `createFeed`에 옵셔널 파라미터를 얹는 대신 별도 케이스로 분리했다(연필 아이콘 등 나머지
        /// 진입점은 이 값을 몰라도 되게).
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
        case authorSearch(String)
        /// 작가 이름 검색 화면에서 검색어를 지우면 브라우즈(장르·키워드 섹션)로 돌아가므로, 이 탭도
        /// 상세탐색 결과·필터로 갈 수 있다(#236 — 예전엔 placeholder였다. `HomeRootView`와 동일 규칙).
        case detailSearchFilter(DetailSearchFilterTab)
        case detailSearch(SearchFilter)
        case novelReview(novelID: NovelID, title: String, status: ReadingStatus)
    }

    let dependencies: AppDependencies
    /// 앱 밖에서 들어온 딥링크(#228) — `MainTabView`가 이 탭이 선택돼 있을 때만 값을 준다. 받으면 스택
    /// 위에 push하고 `onDeepLinkConsumed`로 돌려준다(`HomeRootView`와 동일 규칙).
    let deepLink: DeepLink?
    let onDeepLinkConsumed: () -> Void
    /// 딥링크로 push한 화면이 스택에서 빠지면 발화(`HomeRootView`와 동일 규칙).
    let onDeepLinkDestinationDismissed: () -> Void
    /// 이 화면이 push하는 작품 상세의 API 호출이 401(갱신 실패 포함)로 막히면 발화 — idempotent해야 한다.
    let onAuthenticationRequired: () -> Void

    @State private var path = NavigationPath()
    @State private var deepLinkDestinationDepth: Int?
    /// "작품 추가"/"서재에서 추가" 확정 결과를 컬렉션 수정 화면에 돌려주는 1회성 nil→값 채널(#228,
    /// `MypageRootView`와 동일 — 확정(return) 값이라 `Destination` 레이스 대상이 아니다).
    @State private var pendingCollectionNovelSelection: [CollectionNovel]?
    /// 크로스스크린 완료 피드백(#236) — push된 화면이 pop되며 남긴 완료("차단했어요"·"작성 완료!"·
    /// "평가 완료!")를 복귀 화면 위 토스트로 알린다(`CrossScreenFeedback.swift` 참고, 4탭 공통).
    @State private var crossScreenFeedback = CrossScreenFeedbackState()
    /// 연필 아이콘 작성 성공 복귀 신호(#256) — 피드 탭 목록(`SosoFeedView`)이 onAppear에서 소비해 두 목록을
    /// 초기 로드처럼 다시 받는다. 작품 상세 경유 작성(`.createFeedFromNovel`)은 이 신호를 켜지 않는다.
    @State private var needsFeedListReloadForCreatedFeed = false
    /// 작품 상세발 피드 작성(`.createFeedFromNovel`) 성공 복귀 신호(#256) — 복귀한 그 작품 상세가
    /// onAppear에서 소비해 자기 피드 섹션을 초기 로드처럼 리셋한다(4탭 공통 배선).
    @State private var needsNovelDetailFeedReload = false

    /// 로그인 직후 `syncUserBasicInfo()`가 채워두는 로컬 캐시(`FeedDetailAssembly.currentUserID`와 동일
    /// 출처) — 내 프로필로의 "타유저 프로필" 진입을 막는 라우팅 가드에 쓴다.
    private var currentUserID: UserID? {
        UserDefaultsStorage().get(.userID).map(UserID.init)
    }

    var body: some View {
        NavigationStack(path: $path) {
            FeedFeatureFactory.makeSosoFeedView(
                loadMyFeedsUseCase: DefaultLoadMyFeedsUseCase(feedRepository: dependencies.feedRepository),
                loadSosoFeedsUseCase: DefaultLoadSosoFeedsUseCase(feedRepository: dependencies.feedRepository),
                loadFeedDetailUseCase: DefaultLoadFeedUseCase(feedRepository: dependencies.feedRepository),
                feedLikeUseCase: DefaultLikeUseCase(feedRepository: dependencies.feedRepository),
                loadProfileUseCase: DefaultLoadProfileUseCase(profileRepository: dependencies.profileRepository),
                deleteFeedUseCase: DefaultDeleteFeedUseCase(repository: dependencies.feedRepository),
                reportSpoilerFeedUseCase: DefaultReportSpoilerFeedUseCase(repository: dependencies.socialRepository),
                reportImproperFeedUseCase: DefaultReportImproperFeedUseCase(repository: dependencies.socialRepository),
                logger: dependencies.logger,
                // 연필 아이콘 작성 성공 복귀 시에만 켜지는 1회성 신호 — 목록이 새 글을 받는 유일한 경로(#256).
                needsReloadForCreatedFeed: $needsFeedListReloadForCreatedFeed,
                onRoute: { route in
                    switch route {
                    case .feedDetail(let feedID):
                        path.append(Destination.feed(feedID))
                    case .createFeed:
                        path.append(Destination.createFeed)
                    case .editFeed(let feedID):
                        path.append(Destination.editFeed(feedID))
                    case .userProfile(let userID):
                        // `TotalFeed.isMyFeed`로 Feature 쪽에서 이미 내 프로필 탭 자체를 막지만(#196),
                        // 여기서도 한 번 더 막는다 — 라우팅이 실제로 일어나는 지점이라 여기서 막아야
                        // Feature/서버의 isMyFeed 판단이 어긋나는 경우에도 내 프로필로는 절대 안 간다는
                        // 게 보장된다(`FeedDetailAssembly.currentUserID`와 같은 로컬 캐시 비교).
                        guard userID != currentUserID else { return }
                        path.append(Destination.userPage(userID))
                    case .novelDetail(let novelID):
                        path.append(Destination.novel(novelID))
                    }
                }
            )
            .navigationDestination(for: Destination.self) { destination in
                Group {
                    switch destination {
                    case .feed(let feedID):
                        feedDetailView(feedID)
                    case .novel(let novelID):
                        novelDetailView(novelID)
                    case .notificationDetail(let id):
                        notificationDetailView(id)
                    case .createFeed:
                        createFeedView(connectedNovel: nil, reloadsFeedListOnSubmit: true)
                    case .createFeedFromNovel(let connectedNovel):
                        createFeedView(connectedNovel: connectedNovel, reloadsFeedListOnSubmit: false)
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
                            onRoute: { route in
                                switch route {
                                case .userLibrary:
                                    path.append(Destination.userLibrary(userID))
                                case .userFeedList(let userID, let nickname, let profileImage):
                                    path.append(Destination.userFeedList(userID: userID, nickname: nickname, profileImage: profileImage))
                                case .collectionDetail(let collectionID):
                                    path.append(Destination.collectionDetail(collectionID))
                                case .collectionList:
                                    path.append(Destination.collectionList(userID))
                                }
                            },
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
                            onRoute: { route in
                                switch route {
                                case .novelDetail(let novelID):
                                    path.append(Destination.novel(novelID))
                                case .editCollection:
                                    path.append(Destination.editCollection(id))
                                }
                            }
                        )
                    case .collectionList(let userID):
                        CollectionListAssembly.makeView(
                            userID: userID,
                            dependencies: dependencies,
                            onAuthenticationRequired: onAuthenticationRequired,
                            onRoute: { route in
                                switch route {
                                case .collectionDetail(let collectionID):
                                    path.append(Destination.collectionDetail(collectionID))
                                case .createCollection:
                                    // 타유저 컬렉션 목록(isOwnCollections=false)엔 "만들기" 버튼이 안 떠 도달 불가.
                                    break
                                }
                            }
                        )
                    case .editCollection(let id):
                        editCollectionView(id: id)
                    case .searchNovelForCollection(let initialSelection):
                        collectionSearchNovelView(initialSelection: initialSelection)
                    case .myLibrarySelectForCollection(let initialSelection):
                        collectionMyLibrarySelectView(initialSelection: initialSelection)
                    case .authorSearch(let authorName):
                        authorSearchView(authorName)
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
                    }
                }
            }
        }
        .hidesTabBar(when: !path.isEmpty)
        .onChange(of: deepLink, initial: true) { _, deepLink in
            guard let deepLink else { return }
            switch deepLink {
            case .collectionDetail(let id):
                path.append(Destination.collectionDetail(id))
            case .novelDetail(let id):
                path.append(Destination.novel(id))
            case .feedDetail(let id):
                path.append(Destination.feed(id))
            case .notificationDetail(let id):
                path.append(Destination.notificationDetail(id))
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

// MARK: - 컬렉션 수정 (#228 — 딥링크로 "내" 컬렉션이 이 탭 위에 열릴 수 있어 4탭 공통. 조립은
// `CollectionEditAssembly`, pop 핸들러만 이 Root가 갖는다 — `MypageRootView`와 동일 구조)

private extension FeedRootView {
    func editCollectionView(id: CollectionID) -> some View {
        CollectionEditAssembly.makeEditView(
            id: id,
            dependencies: dependencies,
            pendingNovelSelection: $pendingCollectionNovelSelection,
            onRoute: { route in
                switch route {
                case .addNovel(let currentSelection):
                    handleCollectionAddNovelTapped(currentSelection)
                }
            },
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    func collectionSearchNovelView(initialSelection: [CollectionNovel]) -> some View {
        CollectionEditAssembly.makeSearchNovelView(
            initialSelection: initialSelection,
            dependencies: dependencies,
            onConfirm: handleCollectionSearchNovelConfirm,
            onRoute: { route in
                switch route {
                case .myLibrarySelect(let currentSelection):
                    handleCollectionLibrarySelectTapped(currentSelection)
                }
            },
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

// MARK: - 피드 상세

private extension FeedRootView {
    func feedDetailView(_ feedID: FeedID) -> some View {
        FeedDetailAssembly.makeView(
            feedID: feedID,
            dependencies: dependencies,
            onRoute: { route in
                switch route {
                case .novelDetail(let novelID):
                    path.append(Destination.novel(novelID))
                case .editFeed(let feedID):
                    path.append(Destination.editFeed(feedID))
                case .userProfile(let userID):
                    // 피드 탭 셀의 프로필 탭과 같은 이중 가드(#196) — 내 프로필로는 절대 안 간다.
                    guard userID != currentUserID else { return }
                    path.append(Destination.userPage(userID))
                }
            },
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}

// MARK: - 작품 상세 (피드 상세의 연결 작품 배너 탭)

private extension FeedRootView {
    func novelDetailView(_ novelID: NovelID) -> some View {
        NovelDetailAssembly.makeView(
            novelID: novelID,
            dependencies: dependencies,
            needsFeedReloadForCreatedFeed: $needsNovelDetailFeedReload,
            onRoute: { route in
                switch route {
                case .review(let information, let status):
                    path.append(Destination.novelReview(novelID: information.novel.id, title: information.novel.title, status: status))
                case .createFeed(let connectedNovel):
                    path.append(Destination.createFeedFromNovel(connectedNovel))
                case .feedDetail(let feedID):
                    path.append(Destination.feed(feedID))
                case .userProfile(let userID):
                    // 피드 탭 셀의 프로필 탭과 같은 이중 가드(#196) — 내 프로필로는 절대 안 간다.
                    guard userID != currentUserID else { return }
                    path.append(Destination.userPage(userID))
                case .novelDetail(let novelID):
                    path.append(Destination.novel(novelID))
                case .editFeed(let feedID):
                    path.append(Destination.editFeed(feedID))
                case .authorSearch(let name):
                    path.append(Destination.authorSearch(name))
                }
            },
            onAuthenticationRequired: onAuthenticationRequired
        )
    }

    /// 공지 푸시 딥링크(#243) 전용 — 이 탭엔 알림 목록이 없어 딥링크로만 도달한다(`NotificationDetailAssembly`).
    func notificationDetailView(_ notificationID: NotificationID) -> some View {
        NotificationDetailAssembly.makeView(
            notificationID: notificationID,
            dependencies: dependencies,
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}

// MARK: - 작가 이름 검색 (작품 상세 헤더의 작가 이름 탭)

private extension FeedRootView {
    /// 피드 탭엔 일반 검색 진입점(검색 버튼)이 없어 `.search` 케이스가 아예 없다 — 작가 이름 검색
    /// 전용으로만 이 화면을 조립한다. 단 검색어를 지우면 브라우즈(장르·키워드 섹션)로 돌아가므로
    /// 상세탐색 결과·필터 경로는 다른 탭과 동일하게 배선한다(#236 — 예전 placeholder를 해소).
    func authorSearchView(_ authorName: String) -> some View {
        SearchAssembly.makeView(
            dependencies: dependencies,
            onRoute: { route in
                switch route {
                case .novelDetail(let novelID):
                    path.append(Destination.novel(novelID))
                case .detailSearchResult(let filter):
                    path.append(Destination.detailSearch(filter))
                case .detailSearchFilter(let tab):
                    path.append(Destination.detailSearchFilter(tab))
                }
            },
            initialQuery: authorName
        )
    }

    func detailSearchFilterView(initialTab: DetailSearchFilterTab) -> some View {
        SearchAssembly.makeDetailSearchFilterView(
            initialTab: initialTab,
            dependencies: dependencies,
            onSearch: { filter in path.append(Destination.detailSearch(filter)) }
        )
    }

    func detailSearchResultView(_ filter: SearchFilter) -> some View {
        SearchAssembly.makeDetailSearchResultView(
            filter: filter,
            dependencies: dependencies,
            onRoute: { route in
                switch route {
                case .novelDetail(let novelID):
                    path.append(Destination.novel(novelID))
                }
            }
        )
    }
}

// MARK: - 피드 작성

private extension FeedRootView {
    /// `.createFeed`(연필 아이콘)는 `nil`로, `.createFeedFromNovel`(작품 상세)은 그 작품으로 이 헬퍼를
    /// 공유한다 — `connectedNovel`이 있으면 작성 화면이 그 작품이 미리 연결된 상태로 뜬다.
    /// `reloadsFeedListOnSubmit`은 연필 아이콘 경로만 true(#256) — 작성 성공 복귀 시 피드 탭 목록이 두 목록을
    /// 초기 로드처럼 다시 받는다. 작품 상세 경유 작성은 그 작품 상세가 자기 피드 섹션을 리셋하므로(사용자 확정)
    /// 이 목록엔 신호를 보내지 않는다.
    func createFeedView(connectedNovel: ConnectedNovel?, reloadsFeedListOnSubmit: Bool) -> some View {
        FeedFeatureFactory.makeCreateFeedView(
            createFeedUseCase: DefaultCreateFeedUseCase(repository: dependencies.feedRepository),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository),
            appReviewUseCase: DefaultAppReviewRequestUseCase(repository: dependencies.appReviewRequestRepository),
            connectedNovel: connectedNovel,
            onSubmitted: {
                crossScreenFeedback.present(.feedEdited)
                if reloadsFeedListOnSubmit {
                    needsFeedListReloadForCreatedFeed = true
                } else {
                    // 작품 상세 경유(.createFeedFromNovel) — 복귀할 그 작품 상세가 자기 피드 섹션을 리셋한다.
                    needsNovelDetailFeedReload = true
                }
            }
        )
    }
}

// MARK: - 타유저 서재 (타유저 프로필의 서재 블록 탭)

private extension FeedRootView {
    func userLibraryView(_ userID: UserID) -> some View {
        LibraryFeatureFactory.makeUserLibraryView(
            userID: userID,
            loadUserLibraryUseCase: DefaultLoadUserLibraryUseCase(
                novelRepository: dependencies.novelRepository,
                keywordRepository: dependencies.keywordRepository
            ),
            logger: dependencies.logger,
            onRoute: { route in
                switch route {
                case .novelDetail(let novelID):
                    path.append(Destination.novel(novelID))
                }
            },
            onAuthenticationRequired: onAuthenticationRequired
        )
    }
}
