//
//  UserFeedListView.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

import BaseDomain
import FeedDomain
import SocialDomain

struct UserFeedListView: View {

    /// 피드 셀 threedots 드롭다운 표시 컨텍스트 — 대상 피드(신고 항목 확정용)와 앵커(threedots 하단의 화면 y).
    struct FeedMenuContext {
        let feed: TotalFeed
        let anchorY: CGFloat
    }

    @State private var viewModel: UserFeedListViewModel

    @State private var feedMenuContext: FeedMenuContext?
    @State private var feedCellTopYs: [FeedID: CGFloat] = [:]

    @Environment(\.dismiss) private var dismiss

    /// 피드 셀 탭 → 피드 상세 진입 콜백. 실제 화면 전환은 호출자(App)가 수행한다
    /// (`UserPageView.onFeedTapped`와 동일 계약).
    private let onFeedTapped: (FeedID) -> Void
    /// 피드 셀의 연결 작품 배너 탭 → 작품 상세 진입 콜백. 실제 화면 전환은 호출자(App)가 수행한다.
    private let onNovelTapped: (NovelID) -> Void

    init(
        viewModel: UserFeedListViewModel,
        onFeedTapped: @escaping (FeedID) -> Void = { _ in },
        onNovelTapped: @escaping (NovelID) -> Void = { _ in }
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onFeedTapped = onFeedTapped
        self.onNovelTapped = onNovelTapped
    }

    var body: some View {
        VStack(spacing: 0) {
            WSSNavigationBar(title: "활동") { dismiss() }

            Group {
            if viewModel.state.feeds.isEmpty, let error = viewModel.state.feedsLoadFailed {
                NetworkErrorView(error: error) {
                    viewModel.handle(.load)
                }
            } else if viewModel.state.feeds.isEmpty, viewModel.state.isLoadingFeeds {
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.state.feeds, id: \.feedId) { feed in
                            feedCell(feed)
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear
                                            .onChange(of: proxy.frame(in: .named(scrollCoordinateSpace)).minY,
                                                      initial: true) { _, newY in
                                                feedCellTopYs[feed.feedId] = newY
                                            }
                                    }
                                )
                                // 프로필·좋아요·threedots·연결 작품 배너는 각자 실제 Button이라 자기
                                // hit-test 영역에서 이 onTapGesture보다 우선한다 — 그 영역 밖만
                                // 여기로 떨어져 피드 상세로 이동한다(`UserPageView`와 동일 패턴).
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onFeedTapped(feed.feedId)
                                }
                                .onAppear {
                                    if feed == viewModel.state.feeds.last {
                                        viewModel.handle(.loadMoreFeeds)
                                    }
                                }
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
                        }

                        if viewModel.state.isLoadingFeeds {
                            ProgressView()
                                .padding(.vertical, 20)
                        }
                    }
                }
                .coordinateSpace(name: scrollCoordinateSpace)
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .overlay(alignment: .topTrailing) {
                    if let feedMenuContext {
                        feedMenuOverlay(feedMenuContext)
                    }
                }
            }
        }
        }
        .background(WSSColor.wssWhite.swiftUIColor)
        .wssCustomNavigationBar()
        .showWSSAlert(
            isPresented: feedAlertBinding,
            type: feedAlertType,
            buttonActions: feedAlertActions
        )
        .showWSSToast(isPresented: actionErrorToastBinding, type: .unknownError)
        .showWSSToast(isPresented: alreadyReportedToastBinding, type: .alreadyReportedFeed)
        .onAppear {
            viewModel.handle(.load)
        }
    }

    /// 도메인 `TotalFeed` → 공용 피드 셀 입력값 매핑(`UserPageView.feedCell`과 동일 매핑).
    private func feedCell(_ feed: TotalFeed) -> some View {
        WSSFeadView(
            header: FeedHeader(
                profileImageURL: feed.author.profileImage,
                nickname: feed.author.nickname,
                createdDate: feed.createdDate,
                isEdited: feed.isModified
            ),
            profileImageTapped: {},
            threeDotsButtonTapped: {
                // 셀 상단 패딩(20) + 헤더 높이(32) = 52. NovelDetailFeedTab과 동일 계산.
                feedMenuContext = FeedMenuContext(feed: feed, anchorY: (feedCellTopYs[feed.feedId] ?? 0) + 52)
            },
            content: feed.content,
            feedImage: feed.thumbnailImageURL.map {
                WSSFeedImage(thumbnailImageURL: $0, imageCount: feed.imageCount)
            },
            linkNovel: feed.connectedNovel.flatMap { connected in
                connected.genre.map {
                    WSSLinkNovel(
                        genreType: $0,
                        novelTitle: connected.title,
                        novelRating: connected.rating ?? 0,
                        linkNovelTapped: {
                            onNovelTapped(connected.id)
                        }
                    )
                }
            },
            react: WSSFeedReact(
                likeCount: feed.likeCount,
                commentCount: feed.commentCount
            ),
            isLiked: feed.isLiked,
            likeButtonTapped: {
                viewModel.handle(.toggleFeedLike(feed.feedId))
            },
            isSpoiler: feed.isSpoiler,
            isPrivate: !feed.isPublic
        )
    }
}

// MARK: - Menu

private extension UserFeedListView {
    /// 피드 셀 threedots 드롭다운(스포일러/부적절한 표현 신고) — `UserPageView`와 동일 항목·색(빨강).
    func feedMenuOverlay(_ context: FeedMenuContext) -> some View {
        ZStack(alignment: .topTrailing) {
            Color.wssBlack.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { feedMenuContext = nil }

            WSSDropdownMenu(items: [
                WSSDropdownItem(
                    title: "스포일러 신고",
                    action: {
                        feedMenuContext = nil
                        viewModel.handle(.reportSpoilerFeedTapped(context.feed.feedId))
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                ),
                WSSDropdownItem(
                    title: "부적절한 표현 신고",
                    action: {
                        feedMenuContext = nil
                        viewModel.handle(.reportImproperFeedTapped(context.feed.feedId))
                    },
                    textColor: WSSColor.wssSecondary100.swiftUIColor
                )
            ])
            .frame(width: 190)
            .padding(.top, context.anchorY)
            .padding(.trailing, 20)
        }
    }
}

// MARK: - Presentation

private extension UserFeedListView {
    var feedAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedFeedAlert != nil },
            set: { if !$0 { viewModel.handle(.dismissFeedAlert) } }
        )
    }

    var feedAlertType: WSSAlertType {
        switch viewModel.state.presentedFeedAlert {
        case .reportSpoiler, nil: .reportSpoilerContent
        case .reportImproper: .reportImproperContent
        case .reportSpoilerCompleted: .receivedReportSpoilerContent
        case .reportImproperCompleted: .receivedReportImproperContent
        }
    }

    var feedAlertActions: [() -> Void] {
        switch viewModel.state.presentedFeedAlert {
        case .reportSpoiler, .reportImproper, nil:
            [
                { viewModel.handle(.dismissFeedAlert) },
                { viewModel.handle(.confirmFeedAlert) }
            ]
        case .reportSpoilerCompleted, .reportImproperCompleted:
            [
                { viewModel.handle(.dismissFeedAlert) }
            ]
        }
    }

    var actionErrorToastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.hasActionError },
            set: { if !$0 { viewModel.handle(.dismissActionErrorToast) } }
        )
    }

    var alreadyReportedToastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isAlreadyReportedToastPresented },
            set: { if !$0 { viewModel.handle(.dismissAlreadyReportedToast) } }
        )
    }
}

// MARK: - Scroll Coordinate Space

private let scrollCoordinateSpace = "UserFeedListScroll"

// MARK: - Preview

#Preview {
    NavigationStack {
        UserFeedListView(
            viewModel: UserFeedListViewModel(
                userID: UserID(1),
                nickname: "구리구리스",
                profileImage: nil,
                loadUserFeedsUseCase: PreviewLoadUserFeedsUseCase(),
                feedLikeUseCase: PreviewFeedLikeUseCase(),
                reportSpoilerFeedUseCase: PreviewReportSpoilerFeedUseCase(),
                reportImproperFeedUseCase: PreviewReportImproperFeedUseCase()
            )
        )
    }
}

private struct PreviewLoadUserFeedsUseCase: LoadUserFeedsUseCase {
    func execute(userID: UserID, nickname: String, profileImage: URL?, lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        let feeds = (1...8).map { index in
            TotalFeed(
                feedId: FeedID(index),
                createdDate: "2026년 7월 25일",
                content: "이 작품은 너무 재밌어요 \(index)",
                author: Author(userId: userID, nickname: nickname, profileImage: profileImage),
                likeCount: 13,
                isLiked: false,
                commentCount: 3,
                isSpoiler: false,
                isModified: false,
                isPublic: true,
                isMyFeed: false,
                imageCount: 0
            )
        }
        return Paginated(items: feeds, hasNext: false)
    }
}

private struct PreviewFeedLikeUseCase: FeedLikeUseCase {
    func like(feedID: FeedID) async throws(RepositoryError) {}
    func unlike(feedID: FeedID) async throws(RepositoryError) {}
}

private struct PreviewReportSpoilerFeedUseCase: ReportSpoilerFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) {}
}

private struct PreviewReportImproperFeedUseCase: ReportImproperFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) {}
}
