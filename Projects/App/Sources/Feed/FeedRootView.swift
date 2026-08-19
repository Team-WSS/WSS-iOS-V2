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
/// 우상단 연필 아이콘 탭 시 피드 작성, 작성자 프로필 탭 시 타유저 프로필(`UserPageAssembly`), 연결 작품
/// 배너 탭 시 작품 상세, 그 타유저 프로필의 서재 블록 탭 시 타유저 서재(`LibraryFactory.makeUserLibraryView`)
/// 까지 push한다. 피드 수정(`makeEditFeedView`)은 아직 진입할 방법이 없어 placeholder로 남아있다.
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
        case userPage(UserID)
        case userLibrary(UserID)
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
                        createFeedView
                    case .userPage(let userID):
                        UserPageAssembly.makeView(
                            userID: userID,
                            dependencies: dependencies,
                            onLibraryTapped: { path.append(Destination.userLibrary(userID)) }
                        )
                    case .userLibrary(let userID):
                        userLibraryView(userID)
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
            onNovelTapped: { path.append(Destination.novel($0)) }
        )
    }
}

// MARK: - 작품 상세 (피드 상세의 연결 작품 배너 탭)

private extension FeedRootView {
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

// MARK: - 피드 작성

private extension FeedRootView {
    var createFeedView: some View {
        FeedFeatureFactory.makeCreateFeedView(
            createFeedUseCase: DefaultCreateFeedUseCase(repository: dependencies.feedRepository),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository)
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
