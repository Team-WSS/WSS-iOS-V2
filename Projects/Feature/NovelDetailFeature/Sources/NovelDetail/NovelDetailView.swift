//
//  NovelDetailView.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import NovelDomain
import DesignSystem
import WSSComponent

// 작품 상세 화면: 몰입형 헤더(블러 커버) + 유저 평가 + 탭(정보/피드).
// "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
struct NovelDetailView: View {

    @State private var viewModel: NovelDetailViewModel
    /// VM 판단이 필요 없는 순수 표시 상태 — View가 소유한다.
    @State private var isMenuPresented = false
    @State private var isDescriptionExpanded = false
    @Environment(\.dismiss) private var dismiss
    /// 작품 평가(NovelReviewFeature) 진입 콜백. Feature 간 직접 의존 금지 —
    /// 화면 전환은 호출자(App 조정 계층)가 수행한다. status는 평가 초안에 seed할 읽기 상태.
    private let onReviewTapped: (NovelInformation, ReadingStatus) -> Void
    /// 피드 작성(CreateFeed) 진입 콜백 — "나도 한마디" 버튼·피드 탭 플로팅 버튼 공용.
    private let onCreateFeedTapped: () -> Void

    init(
        viewModel: NovelDetailViewModel,
        onReviewTapped: @escaping (NovelInformation, ReadingStatus) -> Void,
        onCreateFeedTapped: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onReviewTapped = onReviewTapped
        self.onCreateFeedTapped = onCreateFeedTapped
    }

    // body = 조립 + 화면 modifier만. 몰입형 헤더라 시스템 네비바를 숨기고 커스텀 오버레이를 쓴다.
    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { viewModel.handle(.load) }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss { dismiss() }
            }
    }

    // 루트는 ZStack으로 고정 — 로딩/성공/실패가 분기돼도 루트 정체성이 유지돼
    // pop 애니메이션과 로드 완료가 겹칠 때의 전환 경합을 피한다(NovelReview 교훈).
    private var content: some View {
        ZStack(alignment: .top) {
            Color.wssWhite.ignoresSafeArea()

            if let information = viewModel.state.information {
                loadedContent(information)
            } else if viewModel.state.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 로드 실패 — 공용 실패 뷰 재사용. 재시도 버튼이 load를 다시 발화한다(실패는 가드를 소진하지 않음).
                NetworkErrorView { viewModel.handle(.load) }
            }

            navigationBar

            if isMenuPresented {
                menuOverlay
            }
        }
    }

    private func loadedContent(_ information: NovelInformation) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    NovelDetailHeaderView(
                        information: information,
                        novel: viewModel.state.novel ?? information.novel
                    )
                    NovelDetailReviewSection(
                        information: information,
                        novel: viewModel.state.novel ?? information.novel,
                        onSelectStatus: { onReviewTapped(information, $0) },
                        onToggleInterest: { viewModel.handle(.toggleInterest) },
                        onCreateFeedTapped: onCreateFeedTapped
                    )
                    tabBar
                    switch viewModel.state.selectedTab {
                    case .info:
                        NovelDetailInfoTab(
                            information: information,
                            isDescriptionExpanded: $isDescriptionExpanded
                        )
                    case .feed:
                        NovelDetailFeedTab(
                            feeds: viewModel.state.feeds,
                            isLoading: viewModel.state.isLoadingFeeds,
                            hasLoadFailed: viewModel.state.feedsLoadFailed,
                            onReachEnd: { viewModel.handle(.loadMoreFeeds) }
                        )
                    }
                }
            }
            .ignoresSafeArea(edges: .top)

            if viewModel.state.selectedTab == .feed {
                floatingWriteButton
            }
        }
    }
}

// MARK: - Sections

private extension NovelDetailView {

    /// 뒤로가기 + 더보기(threedots). 몰입형 헤더 위에 떠 있는 고정 영역이라 시스템 툴바 대신 직접 그린다.
    var navigationBar: some View {
        HStack(spacing: 0) {
            // 에셋 원색(wssGray100)은 밝은 헤더 배경에서 안 보여 template으로 진한 색을 입힌다.
            // contentShape는 라벨 내부에 둬야 투명 여백까지 탭이 먹는다(레퍼런스 배치).
            Button {
                viewModel.handle(.requestClose)
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color.wssBlack)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                isMenuPresented.toggle()
            } label: {
                WSSImage.icThreedots.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Color.wssBlack)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 6)
        .padding(.trailing, 12)
    }

    /// threedots 드롭다운(오류 제보 / 평가 삭제). 실제 동작은 이번 범위 밖(TODO — #154 이후 이슈).
    var menuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            // 바깥 탭으로 닫기 위한 투명 레이어.
            Color.wssBlack.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { isMenuPresented = false }

            WSSDropdownMenu(items: [
                WSSDropdownItem(title: "오류 제보") { isMenuPresented = false },
                WSSDropdownItem(title: "평가 삭제") { isMenuPresented = false }
            ])
            .frame(width: 120)
            .padding(.top, 44)
            .padding(.trailing, 20)
        }
    }

    var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(NovelDetailViewModel.Tab.allCases, id: \.self) { tab in
                tabItem(tab)
            }
        }
        .background(Color.wssWhite)
    }

    func tabItem(_ tab: NovelDetailViewModel.Tab) -> some View {
        let isSelected = viewModel.state.selectedTab == tab
        return Button {
            viewModel.handle(.selectTab(tab))
        } label: {
            VStack(spacing: 0) {
                Spacer().frame(height: 15)
                Text(tabTitle(tab))
                    .applyWSSFont(.title2)
                    .foregroundStyle(isSelected ? Color.wssBlack : Color.wssGray200)
                Spacer().frame(height: 15)
                // 밑줄 두께(선택 2/비선택 1)가 달라도 항목 높이가 같도록 2pt 슬롯에 bottom 정렬.
                Rectangle()
                    .fill(isSelected ? Color.wssBlack : Color.wssGray70)
                    .frame(height: isSelected ? 2 : 1)
                    .frame(height: 2, alignment: .bottom)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 피드 탭 전용 플로팅 작성 버튼.
    var floatingWriteButton: some View {
        Button {
            onCreateFeedTapped()
        } label: {
            UnevenRoundedRectangle(
                topLeadingRadius: 54.75,
                bottomLeadingRadius: 54.75,
                bottomTrailingRadius: 9.125,
                topTrailingRadius: 54.75
            )
            .fill(Color.wssBlack)
            .frame(width: 65, height: 65)
            .overlay {
                WSSImage.icPencil.swiftUIImage
                    .resizable()
                    .frame(width: 26, height: 26)
            }
            .shadow(color: Color.wssBlack.opacity(0.1), radius: 5.3, x: 5, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 26)
        .padding(.bottom, 25)
    }
}

// MARK: - Presentation

private extension NovelDetailView {

    func tabTitle(_ tab: NovelDetailViewModel.Tab) -> String {
        switch tab {
        case .info: "정보"
        case .feed: "피드"
        }
    }

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedError != nil },
            set: { if !$0 { viewModel.handle(.dismissError) } }
        )
    }

    /// 에러 의미값 → 토스트 표현. 케이스별 전용 문구가 필요해지면 WSSToastType에 케이스를 더한다(허락 후).
    var toastType: WSSToastType {
        .unknownError
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NovelDetailView(
            viewModel: NovelDetailViewModel(
                novelID: NovelID(1),
                loadNovelUseCase: PreviewLoadNovelUseCase(),
                novelInterestUseCase: PreviewNovelInterestUseCase(),
                loadNovelFeedsUseCase: PreviewLoadNovelFeedsUseCase()
            ),
            onReviewTapped: { _, status in print("리뷰 진입: \(status)") },
            onCreateFeedTapped: { print("피드 작성 진입") }
        )
    }
}

private struct PreviewLoadNovelUseCase: LoadNovelUseCase {
    func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        NovelInformation(
            novel: Novel(
                id: id,
                thumbnailImage: nil,
                title: "당신의 이해를 돕기 위하여",
                authors: ["이보라"],
                genres: [.romanceFantasy],
                interestCount: 128,
                rating: 4.4,
                ratingCount: 52,
                isInterested: false
            ),
            feedCount: 3,
            genres: [.romanceFantasy],
            publicationStatus: .completed,
            userReview: nil,
            description: "왕실에는 막대한 빚이 있었고, 그들은 빚을 갚기 위해 왕녀인 바이올렛을 막대한 돈을 지녔지만 공작의 사생아인 윈터에게 시집보낸다.",
            platforms: [],
            attractivePoints: [.character, .relationship, .writingSkill],
            keywords: [],
            readingStatusCount: [.watching: 130, .watched: 10, .quit: 100]
        )
    }
}

private struct PreviewNovelInterestUseCase: NovelInterestUseCase {
    func add(id: NovelID) async throws(RepositoryError) {}
    func remove(id: NovelID) async throws(RepositoryError) {}
}

private struct PreviewLoadNovelFeedsUseCase: LoadNovelFeedsUseCase {
    func execute(novelID: NovelID,
                 lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        Paginated(items: [], hasNext: false)
    }
}
