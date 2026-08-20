//
//  SosoFeedView.swift
//  FeedFeature
//
//  Created by Seoyeon Choi on 6/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import ProfileDomain
import SocialDomain
import DesignSystem
import WSSComponent

struct SosoFeedView: View {

    /// 피드 셀 threedots 드롭다운 표시 컨텍스트 — 대상 피드(항목 분기)와 앵커(threedots 하단의 화면 y).
    struct FeedMenuContext {
        let feed: TotalFeed
        let anchorY: CGFloat
    }

    @State private var viewModel: SosoFeedViewModel

    @State private var showMyFeedFilterSheet: Bool = false

    /// 피드 셀 threedots 드롭다운 — nil이 아니면 해당 피드의 메뉴가 떠 있다. VM 판단이 필요 없는 순수 표시 상태.
    @State private var feedMenuContext: FeedMenuContext?
    /// 각 셀 상단의 화면 y(루트 좌표공간 실측) — threedots 앵커 계산용.
    @State private var cellTopYs: [FeedID: CGFloat] = [:]
    /// 드롭다운이 화면 밖으로 잘리지 않게 클램프하기 위한 화면 가용 높이.
    @State private var containerHeight: CGFloat = 0

    @Namespace private var tabAnimation

    /// 피드 수정 진입 콜백 — 내 글 드롭다운의 "수정하기". 대상 피드 `FeedID`만 넘긴다 — 실제 데이터
    /// 로드는 수정 화면 자신이 하므로 화면 전환(`makeEditFeedView` 조립)은 호출자(App 조정 계층)가
    /// 값만 그대로 받아 하면 된다.
    private let onEditFeedTapped: (FeedID) -> Void
    /// 피드 셀 탭(좋아요 버튼 등 안쪽 인터랙션 제외) → 피드 상세 진입 콜백. 화면 전환은 호출자가 수행한다.
    private let onFeedTapped: (FeedID) -> Void
    /// 우상단 연필 아이콘 → 피드 작성 진입 콜백. 화면 전환은 호출자가 수행한다.
    private let onCreateFeedTapped: () -> Void
    /// 작성자 프로필(이미지+닉네임) 탭 → 유저 프로필 진입 콜백. `Author.userId`가 nil이면 호출하지 않는다.
    private let onUserProfileTapped: (UserID) -> Void
    /// 연결 작품 배너 탭 → 작품 상세 진입 콜백.
    private let onNovelTapped: (NovelID) -> Void

    /// 셀 상단 → threedots 하단 거리 = 셀 상단 패딩(20) + 헤더 높이(32). 드롭다운이 이 바로 아래에 뜬다.
    private let threeDotsBottomOffset: CGFloat = 52

    private let feedMenuSpaceName = "sosoFeedRoot"

    init(
        viewModel: SosoFeedViewModel,
        onEditFeedTapped: @escaping (FeedID) -> Void = { _ in },
        onFeedTapped: @escaping (FeedID) -> Void = { _ in },
        onCreateFeedTapped: @escaping () -> Void = {},
        onUserProfileTapped: @escaping (UserID) -> Void = { _ in },
        onNovelTapped: @escaping (NovelID) -> Void = { _ in }
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onEditFeedTapped = onEditFeedTapped
        self.onFeedTapped = onFeedTapped
        self.onCreateFeedTapped = onCreateFeedTapped
        self.onUserProfileTapped = onUserProfileTapped
        self.onNovelTapped = onNovelTapped
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                FeedTabSection
                    .padding(.horizontal, 20)

                Spacer().frame(height: 12)

                FeedChipSection
                    .transaction { $0.animation = nil }
                    .padding(.horizontal, 20)

                FeedListSection
            }
            .background(WSSColor.wssWhite.swiftUIColor)

            if let feedMenuContext {
                feedMenuOverlay(feedMenuContext)
            }
        }
        .coordinateSpace(name: feedMenuSpaceName)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.height, initial: true) { _, height in
                        containerHeight = height
                    }
            }
        )
        .sheet(isPresented: $showMyFeedFilterSheet) {
            MyFeedFilterSheet(
                viewModel: viewModel,
                dismiss: { showMyFeedFilterSheet.toggle() }
            )
        }
        .showWSSAlert(
            isPresented: feedAlertBinding,
            type: feedAlertType,
            buttonActions: feedAlertActions
        )
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

            Button(action: onCreateFeedTapped) {
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
                              action: {
                    HapticManager.selection()
                    viewModel.handle(.toggleMyFeedSort)
                })

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

    /// 탭·소소피드 옵션·내 피드 필터(장르/공개여부/정렬)가 바뀔 때마다 다른 값 — ScrollView의 `.id()`로
    /// 걸어 전환 시 SwiftUI가 새 인스턴스로 취급하게 해 스크롤 위치를 최상단으로 리셋시킨다.
    private var scrollIdentity: String {
        let option = viewModel.state.myFeedOption
        let genresKey = option.genres.map { "\($0)" }.sorted().joined(separator: ",")
        return "\(viewModel.state.selectedTab)_\(viewModel.state.selectedSosoFeedOption.rawValue)"
            + "_\(genresKey)_\(option.includesUncategorized)_\(option.visibilityType)_\(option.sortType.rawValue)"
    }

    @ViewBuilder
    private var FeedListSection: some View {
        if viewModel.state.isLoading, currentFeeds.isEmpty {
            LoadingView()
        } else if viewModel.state.selectedTab == .myFeed,
           currentFeeds.isEmpty {
            WSSEmptyView(type: .myFeed,
                         action: { })
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(currentFeeds, id: \.feedId) { feed in
                        feedRow(feed)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .onChange(of: proxy.frame(in: .named(feedMenuSpaceName)).minY,
                                                  initial: true) { _, newY in
                                            cellTopYs[feed.feedId] = newY
                                        }
                                }
                            )
                            .onAppear {
                                if feed.feedId == currentFeeds.last?.feedId {
                                    viewModel.handle(.loadMore)
                                }
                            }
                            // 프로필·좋아요(Button)·연결 작품 배너(Button)는 각자 실제 Button이라
                            // 자기 hit-test 영역에서 이 onTapGesture보다 우선한다(WSSComponent/CLAUDE.md
                            // "Button은 조상의 onTapGesture보다 우선") — 그 영역 밖만 여기로 떨어져
                            // 피드 상세로 이동한다. 예전엔 이 우선순위가 없어 simultaneousGesture로
                            // 걸었었는데, 그건 안쪽 제스처와 "공존"(동시 발화)이라 좋아요/프로필을
                            // 눌러도 피드 상세로 함께 이동하는 버그가 있었다(#196).
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onFeedTapped(feed.feedId)
                            }
                        Rectangle()
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
                    }
                }
            }
            .id(scrollIdentity)
            .refreshable {
                viewModel.handle(.load)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private func feedRow(_ feed: TotalFeed) -> some View {
        WSSFeadView(
            header: FeedHeader(
                profileImageURL: feed.author.profileImage,
                nickname: feed.author.nickname,
                createdDate: feed.createdDate,
                isEdited: feed.isModified
            ),
            profileImageTapped: {
                // `Author.userId`는 옵셔널 — 없으면(탈퇴 등) 진입할 프로필이 없으니 무시한다.
                guard let userId = feed.author.userId else { return }
                onUserProfileTapped(userId)
            },
            // 내 글이면 내 프로필로 "이동"할 곳이 없다 — 탭 영역 자체를 없애 탭이 셀 나머지 영역과
            // 동일하게 피드 상세 진입으로 흘러가게 한다(죽은 탭 영역을 만들지 않기 위함).
            isProfileTappable: !feed.isMyFeed,
            threeDotsButtonTapped: {
                feedMenuContext = FeedMenuContext(
                    feed: feed,
                    anchorY: (cellTopYs[feed.feedId] ?? 0) + threeDotsBottomOffset
                )
            },
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
                        novelRating: novel.rating ?? 0,
                        linkNovelTapped: { onNovelTapped(novel.id) }
                    )
                }
            },
            react: WSSFeedReact(
                likeCount: feed.likeCount,
                commentCount: feed.commentCount
            ),
            isLiked: feed.isLiked,
            likeButtonTapped: { viewModel.handle(.toggleLike(feed.feedId)) },
            isSpoiler: feed.isSpoiler,
            isPrivate: !feed.isPublic
        )
    }

    //MARK: - 피드 셀 threedots 드롭다운

    /// 화면 하단 셀에서는 앵커를 그대로 쓰면 메뉴가 화면 밖으로 잘린다 →
    /// 전부 보이는 위치까지만 내려가게 클램프한다(threedots에서 떨어져도 전부 보이는 쪽 우선).
    /// 메뉴 높이 107 = WSSDropdownMenu 항목 고정 높이 53 × 2 + 구분선.
    private func feedMenuOverlay(_ context: FeedMenuContext) -> some View {
        let anchorY = containerHeight > 0
            ? min(context.anchorY, containerHeight - 107 - 20)
            : context.anchorY
        return ZStack(alignment: .topTrailing) {
            // 바깥 탭으로 닫기 위한 투명 레이어.
            Color.wssBlack.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { feedMenuContext = nil }

            WSSDropdownMenu(items: feedMenuItems(context.feed))
                .frame(width: 190)
                .padding(.top, anchorY)
                .padding(.trailing, 20)
        }
    }

    /// 피드 소유 여부 → 드롭다운 항목. 내 글 = 수정/삭제, 남의 글 = 신고 2종(빨강).
    private func feedMenuItems(_ feed: TotalFeed) -> [WSSDropdownItem] {
        if feed.isMyFeed {
            [
                WSSDropdownItem(title: "수정하기") {
                    feedMenuContext = nil
                    onEditFeedTapped(feed.feedId)
                },
                WSSDropdownItem(title: "삭제하기") {
                    feedMenuContext = nil
                    viewModel.handle(.deleteFeedTapped(feed.feedId))
                }
            ]
        } else {
            [
                WSSDropdownItem(
                    title: "스포일러 신고",
                    action: {
                        feedMenuContext = nil
                        viewModel.handle(.reportSpoilerFeedTapped(feed.feedId))
                    },
                    textColor: Color.wssSecondary100
                ),
                WSSDropdownItem(
                    title: "부적절한 표현 신고",
                    action: {
                        feedMenuContext = nil
                        viewModel.handle(.reportImproperFeedTapped(feed.feedId))
                    },
                    textColor: Color.wssSecondary100
                )
            ]
        }
    }

    private var feedAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedFeedAlert != nil },
            set: { if !$0 { viewModel.handle(.dismissFeedAlert) } }
        )
    }

    /// 피드 알럿 의미값 → 컴포넌트 알럿 타입. nil일 땐 어떤 타입이든 상관없다(알럿이 숨겨져 있음).
    private var feedAlertType: WSSAlertType {
        switch viewModel.state.presentedFeedAlert {
        case .deleteFeed, nil: .deleteMyFeed
        case .reportSpoiler: .reportSpoilerContent
        case .reportImproper: .reportImproperContent
        case .reportSpoilerCompleted: .receivedReportSpoilerContent
        case .reportImproperCompleted: .receivedReportImproperContent
        }
    }

    /// 알럿 버튼 액션 — 인덱스가 버튼 순서와 일치해야 한다(확인 알럿 [취소, 실행] / 완료 알럿 [확인]).
    private var feedAlertActions: [() -> Void] {
        switch viewModel.state.presentedFeedAlert {
        case .reportSpoilerCompleted, .reportImproperCompleted:
            [{ viewModel.handle(.dismissFeedAlert) }]
        default:
            [
                { viewModel.handle(.dismissFeedAlert) },
                { viewModel.handle(.confirmFeedAlert) }
            ]
        }
    }
}

#Preview {
    SosoFeedView(
        viewModel: SosoFeedViewModel(
            loadMyFeedsUseCase: PreviewLoadMyFeedsUseCase(),
            loadsosoFeedsUseCase: PreviewLoadSosoFeedsUseCase(),
            feedLikeUseCase: PreviewFeedLikeUseCase(),
            loadProfileUseCase: PreviewLoadProfileUseCase(),
            deleteFeedUseCase: PreviewDeleteFeedUseCase(),
            reportSpoilerFeedUseCase: PreviewReportSpoilerFeedUseCase(),
            reportImproperFeedUseCase: PreviewReportImproperFeedUseCase()
        ),
        onEditFeedTapped: { print("피드 수정 진입: \($0)") }
    )
}

private struct PreviewDeleteFeedUseCase: DeleteFeedUseCase {
    func execute(feedID: FeedID) async throws(RepositoryError) { }
}

private struct PreviewReportSpoilerFeedUseCase: ReportSpoilerFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) { }
}

private struct PreviewReportImproperFeedUseCase: ReportImproperFeedUseCase {
    func execute(id: FeedID) async throws(RepositoryError) { }
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
