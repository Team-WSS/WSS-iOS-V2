//
//  SosoFeedView.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem
import WSSComponent
import FeedDomain
import ProfileDomain

struct SosoFeedView: View {

    @State private var viewModel: SosoFeedViewModel

    @State private var showMyFeedFilterSheet: Bool = false

    @Namespace private var tabAnimation

    init(viewModel: SosoFeedViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            FeedTabSection
                .padding(.horizontal, 20)

            Spacer().frame(height: 12)

            FeedChipSection
                .transaction { $0.animation = nil }
                .padding(.horizontal, 20)

            FeedListSection
        }
        .sheet(isPresented: $showMyFeedFilterSheet) {
            MyFeedFilterSheet(
                viewModel: viewModel,
                dismiss: { showMyFeedFilterSheet.toggle() }
            )
            .presentationDetents([.height(520)])
            .presentationBackground(WSSColor.wssWhite.swiftUIColor)
            .presentationCornerRadius(16)
        }
        .onAppear {
            viewModel.handle(.load)
        }
        .onChange(of: viewModel.state.selectedTab) { _, _ in
            viewModel.handle(.load)
        }
        .onChange(of: viewModel.state.selectedSosoFeedOption) { _, _ in
            guard viewModel.state.selectedTab == .sosoFeed else { return }
            viewModel.handle(.load)
        }
    }

    //MARK: - 피드 탭

    private var FeedTabSection: some View {
        HStack(spacing: 16) {
            tabButton(title: "내 피드",
                      tab: .myFeed)

            tabButton(title: "소소피드",
                      tab: .sosoFeed)

            Spacer()

            Button {
                // CreateFeedView로 이동
            } label: {
                WSSImage.icPencilSm.swiftUIImage
            }
        }
    }

    @ViewBuilder
    private func tabButton(title: String,
                           tab: FeedTab) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .applyWSSFont(.headline1)
                .foregroundStyle(
                    viewModel.state.selectedTab == tab
                    ? WSSColor.wssBlack.swiftUIColor
                    : WSSColor.wssGray100.swiftUIColor
                )

            ZStack {
                if viewModel.state.selectedTab == tab {
                    Rectangle()
                        .fill(WSSColor.wssBlack.swiftUIColor)
                        .frame(height: 2)
                        .matchedGeometryEffect(
                            id: "FEED_TAB_INDICATOR",
                            in: tabAnimation
                        )
                } else {
                    Color.clear
                        .frame(height: 2)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.state.selectedTab)
        .onTapGesture {
            viewModel.handle(.selectTab(tab))
        }
        .fixedSize()
    }

    // MARK: - 피드 칩

    @ViewBuilder
    private func sosoFeedChipButton(
        title: String,
        icon: Image? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 4) {
                icon

                Text(title)
            }
            .applyWSSFont(.body4)
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected
                             ? WSSColor.wssWhite.swiftUIColor
                             : WSSColor.wssGray300.swiftUIColor)
            .background(isSelected
                        ? WSSColor.wssBlack.swiftUIColor
                        : WSSColor.wssWhite.swiftUIColor)
            .clipShape(Capsule())
            .overlay {
                if !isSelected {
                    Capsule()
                        .stroke(WSSColor.wssGray80.swiftUIColor, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var FeedChipSection: some View {
        HStack(spacing: 0) {
            switch viewModel.state.selectedTab {
            case .myFeed:
                Button {
                    showMyFeedFilterSheet.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text("\(viewModel.state.myFeeds.count)개의 기록")
                            .applyWSSFont(.body4)
                            .fixedSize()
                            .foregroundStyle(WSSColor.wssWhite.swiftUIColor)

                        WSSImage.icDropdownfill.swiftUIImage
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 13)
                    .background(WSSColor.wssBlack.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)

                Spacer()

                WSSSortButton(sortType: viewModel.state.myFeedOption.sortType,
                              action: { viewModel.handle(.toggleMyFeedSort) })

            case .sosoFeed:
                sosoFeedChipButton(
                    title: "전체글",
                    isSelected: viewModel.state.selectedSosoFeedOption == .all,
                    action: { viewModel.handle(.selectSosoFeedOption(.all)) }
                )

                Spacer().frame(width: 6)

                sosoFeedChipButton(
                    title: "추천글",
                    icon: WSSImage.icHot.swiftUIImage,
                    isSelected: viewModel.state.selectedSosoFeedOption == .recommended,
                    action: { viewModel.handle(.selectSosoFeedOption(.recommended)) }
                )

                Spacer()
            }
        }
        .padding(.vertical, 12)
    }

    //MARK: - 피드 리스트

    private var currentFeeds: [TotalFeed] {
        switch viewModel.state.selectedTab {
        case .myFeed:   viewModel.state.myFeeds
        case .sosoFeed: viewModel.state.sosoFeeds
        }
    }

    private var FeedListSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(currentFeeds, id: \.feedId) { feed in
                    feedRow(feed)
                        .onAppear {
                            if feed.feedId == currentFeeds.last?.feedId {
                                viewModel.handle(.loadMore)
                            }
                        }
                        .onTapGesture {
                            // 피드 상세뷰로 이동
                        }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func feedRow(_ feed: TotalFeed) -> some View {
        WSSFeadView(
            header: FeedHeader(
                profileImageURL: feed.author.profileImage,
                nickname: feed.author.nickname,
                createdDate: feed.createdDate,
                isEdited: feed.isModified,
                profileImageTapped: { },
                threeDotsButtonTapped: { }
            ),
            content: feed.content,
            feedImage: feed.imageCount > 0
                ? WSSFeedImage(
                    thumbnailImageURL: feed.thumbnailImageURL,
                    imageCount: feed.imageCount
                )
                : nil,
            linkNovel: feed.connectedNovel.flatMap { novel in
                novel.genre.map { genre in
                    WSSLinkNovel(
                        genreType: genre,
                        novelTitle: novel.title,
                        novelRating: novel.rating ?? 0
                    )
                }
            },
            react: WSSFeedReact(
                likeCount: feed.likeCount,
                commentCount: feed.commentCount,
                likeButtonTapped: { viewModel.handle(.toggleLike(feed.feedId)) }
            )
        )
    }

}

#Preview {
    SosoFeedView(viewModel: SosoFeedViewModel(
        loadMyFeedsUseCase: PreviewLoadMyFeedsUseCase(),
        loadsosoFeedsUseCase: PreviewLoadSosoFeedsUseCase(),
        feedLikeUseCase: PreviewFeedLikeUseCase(),
        loadProfileUseCase: PreviewLoadProfileUseCase()
    ))
}

private struct PreviewLoadMyFeedsUseCase: LoadMyFeedsUseCase {
    func execute(option: MyFeedOption,
                 lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        Paginated(items: [], hasNext: false)
    }
}

private struct PreviewLoadSosoFeedsUseCase: LoadSosoFeedsUseCase {
    func execute(option: SosoFeedOption,
                 lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        Paginated(items: [], hasNext: false)
    }
}

private struct PreviewFeedLikeUseCase: FeedLikeUseCase {
    func like(feedID: FeedID) async throws(RepositoryError) { }
    func unlike(feedID: FeedID) async throws(RepositoryError) { }
}

private struct PreviewLoadProfileUseCase: LoadProfileUseCase {
    func execute(target: ProfileTarget) async throws(RepositoryError) -> Profile {
        Profile(nickname: "미리보기", introduction: "", characterImage: nil, isPublic: true, genrePreferences: [])
    }
}
