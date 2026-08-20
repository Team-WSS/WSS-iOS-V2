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
import FeedDomain
import FeedFeature
import LibraryFeature
import NovelDomain
import ProfileDomain
import SearchDomain
import SocialDomain

/// "피드" 탭 콘텐츠. `FeedFeatureFactory.makeSosoFeedView`(전체/내 피드)를 붙이고, 셀 탭 시 피드 상세,
/// 피드 셀·피드 상세 "수정" 드롭다운 탭 시 피드 수정(`FeedDetailAssembly.makeEditFeedView`), 우상단 연필
/// 아이콘 탭 시 피드 작성, 작성자 프로필 탭 시 타유저 프로필(`UserPageAssembly`), 연결 작품 배너 탭 시
/// 작품 상세, 그 타유저 프로필의 서재 블록 탭 시 타유저 서재(`LibraryFactory.makeUserLibraryView`), 작품
/// 상세 헤더의 작가 이름 탭 시 그 작가로 사전 검색된 결과 화면(`SearchAssembly.makeView(initialQuery:)`),
/// 작품 상세의 평가 상태바 탭 시 작품 평가(`NovelReviewAssembly`), "나도 한마디"/피드 탭 플로팅 버튼 탭
/// 시 그 작품이 미리 연결된 피드 작성(`createFeedFromNovel`, 연필 아이콘의 `createFeed`와 화면은 같이
/// 쓰되 케이스는 분리 — 아래 주의), 작성자 프로필 탭 시 타유저 프로필(이 화면 자신의 기존 케이스
/// 재사용)까지 push한다.
///
/// ⚠️ **`makeSosoFeedView` 자체는 `onAuthenticationRequired`를 안 받는다** — 그 콜백을 아예 몰라서
/// 소소피드/내 피드 로드가 401로 막혀도 이 화면은 조용히 빈 상태로 남는다(Feature/CLAUDE.md의 "인증
/// 만료 처리 계약"이 이 화면엔 아직 안 들어와 있음, App 쪽에서 고칠 수 있는 부분이 아니라 FeedFeature
/// 쪽 후속 작업). 다만 여기서 push하는 **작품 상세(`NovelDetailFactory`)는 그 콜백을 받으므로**, 그
/// 안에서 발생하는 인증 만료는 정상적으로 처리하도록 `onAuthenticationRequired`를 받아 전달한다.
struct FeedRootView: View {

    /// `NovelID`/`FeedID`가 둘 다 `IDWrapper<Int>`라 타입이 같다 — `HomeRootView.Destination`과 같은
    /// 이유로 래퍼 enum이 필요하다(`App/CLAUDE.md` 참고).
    private enum Destination: Hashable {
        case feed(FeedID)
        case novel(NovelID)
        case createFeed
        /// "나도 한마디"/피드 탭 플로팅 버튼 전용 — 작품 상세에서만 발생하는 흔치 않은 경로라
        /// `createFeed`에 옵셔널 파라미터를 얹는 대신 별도 케이스로 분리했다(연필 아이콘 등 나머지
        /// 진입점은 이 값을 몰라도 되게).
        case createFeedFromNovel(ConnectedNovel)
        case editFeed(FeedID)
        case userPage(UserID)
        case userLibrary(UserID)
        case authorSearch(String)
        case novelReview(novelID: NovelID, title: String, status: ReadingStatus)
    }

    let dependencies: AppDependencies
    /// 이 화면이 push하는 작품 상세의 API 호출이 401(갱신 실패 포함)로 막히면 발화 — idempotent해야 한다.
    let onAuthenticationRequired: () -> Void

    @State private var path = NavigationPath()

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
                feedLikeUseCase: DefaultLikeUseCase(feedRepository: dependencies.feedRepository),
                loadProfileUseCase: DefaultLoadProfileUseCase(profileRepository: dependencies.profileRepository),
                deleteFeedUseCase: DefaultDeleteFeedUseCase(repository: dependencies.feedRepository),
                reportSpoilerFeedUseCase: DefaultReportSpoilerFeedUseCase(repository: dependencies.socialRepository),
                reportImproperFeedUseCase: DefaultReportImproperFeedUseCase(repository: dependencies.socialRepository),
                logger: dependencies.logger,
                onEditFeedTapped: { path.append(Destination.editFeed($0)) },
                onFeedTapped: { path.append(Destination.feed($0)) },
                onCreateFeedTapped: { path.append(Destination.createFeed) },
                onUserProfileTapped: {
                    // `TotalFeed.isMyFeed`로 Feature 쪽에서 이미 내 프로필 탭 자체를 막지만(#196),
                    // 여기서도 한 번 더 막는다 — 라우팅이 실제로 일어나는 지점이라 여기서 막아야
                    // Feature/서버의 isMyFeed 판단이 어긋나는 경우에도 내 프로필로는 절대 안 간다는
                    // 게 보장된다(`FeedDetailAssembly.currentUserID`와 같은 로컬 캐시 비교).
                    guard $0 != currentUserID else { return }
                    path.append(Destination.userPage($0))
                },
                onNovelTapped: { path.append(Destination.novel($0)) }
            )
            .navigationDestination(for: Destination.self) { destination in
                // 탭 콘텐츠에서 push된 화면은 탭바를 가린다(`HomeRootView`와 동일 규칙).
                Group {
                    switch destination {
                    case .feed(let feedID):
                        feedDetailView(feedID)
                    case .novel(let novelID):
                        novelDetailView(novelID)
                    case .createFeed:
                        createFeedView(connectedNovel: nil)
                    case .createFeedFromNovel(let connectedNovel):
                        createFeedView(connectedNovel: connectedNovel)
                    case .editFeed(let feedID):
                        FeedDetailAssembly.makeEditFeedView(feedID: feedID, dependencies: dependencies)
                    case .userPage(let userID):
                        UserPageAssembly.makeView(
                            userID: userID,
                            dependencies: dependencies,
                            onLibraryTapped: { path.append(Destination.userLibrary(userID)) }
                        )
                    case .userLibrary(let userID):
                        userLibraryView(userID)
                    case .authorSearch(let authorName):
                        authorSearchView(authorName)
                    case .novelReview(let novelID, let title, let status):
                        NovelReviewAssembly.makeView(
                            novelID: novelID,
                            title: title,
                            status: status,
                            dependencies: dependencies,
                            onAuthenticationRequired: onAuthenticationRequired
                        )
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
    }
}

// MARK: - 피드 상세

private extension FeedRootView {
    func feedDetailView(_ feedID: FeedID) -> some View {
        FeedDetailAssembly.makeView(
            feedID: feedID,
            dependencies: dependencies,
            onNovelTapped: { path.append(Destination.novel($0)) },
            onEditFeedTapped: { path.append(Destination.editFeed($0)) }
        )
    }
}

// MARK: - 작품 상세 (피드 상세의 연결 작품 배너 탭)

private extension FeedRootView {
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

// MARK: - 작가 이름 검색 (작품 상세 헤더의 작가 이름 탭)

private extension FeedRootView {
    /// 피드 탭엔 일반 검색 진입점(검색 버튼)이 없어 `.search` 케이스가 아예 없다 — 작가 이름 검색
    /// 전용으로만 이 화면을 조립한다. `onDetailSearchRequested`(장르·키워드 칩 탭)는 이 탭에 상세탐색
    /// 결과로 갈 `Destination`이 없어 아직 placeholder(다른 탭의 미구현 콜백과 같은 패턴).
    func authorSearchView(_ authorName: String) -> some View {
        SearchAssembly.makeView(
            dependencies: dependencies,
            onNovelSelected: { path.append(Destination.novel($0)) },
            onDetailSearchRequested: { _ in dependencies.logger.info("상세탐색 결과 진입(미구현) — 피드 탭") },
            initialQuery: authorName
        )
    }
}

// MARK: - 피드 작성

private extension FeedRootView {
    /// `.createFeed`(연필 아이콘)는 `nil`로, `.createFeedFromNovel`(작품 상세)은 그 작품으로 이 헬퍼를
    /// 공유한다 — `connectedNovel`이 있으면 작성 화면이 그 작품이 미리 연결된 상태로 뜬다.
    func createFeedView(connectedNovel: ConnectedNovel?) -> some View {
        FeedFeatureFactory.makeCreateFeedView(
            createFeedUseCase: DefaultCreateFeedUseCase(repository: dependencies.feedRepository),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository),
            connectedNovel: connectedNovel
        )
    }
}

// MARK: - 타유저 서재 (타유저 프로필의 서재 블록 탭)

private extension FeedRootView {
    func userLibraryView(_ userID: UserID) -> some View {
        LibraryFactory.makeUserLibraryView(
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
