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
    /// 스크롤 반응형 네비 타이틀 — 스크롤 콘텐츠 최상단의 오프셋(rest≈0, 위로 스크롤 시 음수).
    /// 조금이라도 스크롤되면 네비 타이틀·흰 배경을 페이드인한다. (loadedContent의 GeometryReader+onChange가 갱신)
    @State private var scrollOffsetY: CGFloat = 0
    /// 스티키 탭바 — 스크롤 콘텐츠 안 "원본" 탭바의 상단 y(화면 좌상단 기준).
    /// 측정 전엔 스티키가 뜨지 않도록 무한대로 시작한다.
    @State private var tabBarMinY: CGFloat = .greatestFiniteMagnitude
    /// 스티키 탭바 — 네비바 하단 y(= 안전영역 top + 네비바 높이). 네비바 배경의 실측 높이로 얻는다.
    @State private var navigationBarBottomY: CGFloat = 0
    /// 탭 콘텐츠 최소 높이 계산용 — 탭바 높이와 스크롤 뷰포트 높이(둘 다 실측).
    @State private var tabBarHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
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

            // 네비바와 스티키 탭바는 한 VStack으로 묶는다 — 탭바가 네비바 "바로 아래"에 붙는 게
            // 레이아웃으로 보장되므로 스티키 탭바의 y를 따로 계산할 필요가 없다.
            VStack(spacing: 0) {
                navigationBar
                if showStickyTabBar {
                    tabBar
                }
            }

            if isMenuPresented {
                menuOverlay
            }
        }
    }

    private func loadedContent(_ information: NovelInformation) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    // 표지는 커스텀 네비바 바로 아래에서 시작한다 — 안전영역 높이가 기기마다 달라
                    // 디자인 고정값(99)을 쓸 수 없다. 네비바 배경 실측 높이를 그대로 인셋으로 넘긴다.
                    NovelDetailHeaderView(
                        information: information,
                        novel: viewModel.state.novel ?? information.novel,
                        topInset: navigationBarBottomY
                    )
                    NovelDetailReviewSection(
                        information: information,
                        novel: viewModel.state.novel ?? information.novel,
                        onSelectStatus: { onReviewTapped(information, $0) },
                        onToggleInterest: { viewModel.handle(.toggleInterest) },
                        onCreateFeedTapped: onCreateFeedTapped
                    )
                    // 스크롤되는 "원본" 탭바 — 자리를 유지해 스티키 전환 시 콘텐츠가 점프하지 않는다.
                    // 네비바 하단에 닿는 순간부터는 상단 오버레이의 탭바가 이 자리를 그대로 덮는다.
                    tabBar
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .onChange(of: proxy.frame(in: .named(scrollSpaceName)).minY,
                                              initial: true) { _, newY in
                                        tabBarMinY = newY
                                    }
                                    .onChange(of: proxy.size.height, initial: true) { _, height in
                                        tabBarHeight = height
                                    }
                            }
                        )
                    // 탭 콘텐츠엔 최소 높이를 준다 — 탭 전환 시 스크롤이 튀지 않게 하는 핵심.
                    // 짧은 탭(피드 몇 개)으로 바뀌면 contentSize가 줄어 UIScrollView가 contentOffset을
                    // 스크롤 가능한 최대치로 되돌린다(클램프) → 화면이 위로 튄다.
                    // 최소 높이를 "탭바 아래 남는 화면 영역"만큼 확보하면 스티키 지점까지의 스크롤 여유가
                    // 항상 남아 클램프가 일어나지 않는다.
                    Group {
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
                    .frame(minHeight: tabContentMinHeight, alignment: .top)
                }
                // 스크롤 오프셋 측정 → scrollOffsetY. rest≈0, 위로 스크롤 시 음수.
                // ⚠️ preference/onPreferenceChange를 안 쓴다 — ScrollView가 preference를 바깥으로
                // 안 올려보내고, 이 SDK에선 onPreferenceChange→@State 갱신도 안 먹는다.
                // GeometryReader 안에서 onChange로 @State를 직접 쓴다(스크롤마다 재평가).
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: proxy.frame(in: .named(scrollSpaceName)).minY,
                                      initial: true) { _, newY in
                                scrollOffsetY = newY
                            }
                    }
                )
                // 상단 over-scroll만 제거(하단 bounce는 유지) — 최상단에서 빈 영역까지 끌려가지 않게 한다.
                .background(TopBounceDisabler())
            }
            .coordinateSpace(name: scrollSpaceName)
            .ignoresSafeArea(edges: .top)
            // 뷰포트 높이 — ⚠️ `GeometryReader`에도 `ignoresSafeArea(edges: .top)`을 걸어야 한다.
            // ScrollView는 이미 상태바까지 확장돼 있는데, background의 GeometryReader는 그대로 두면
            // 안전영역 **안쪽** 높이를 보고한다 → 최소 높이가 딱 안전영역 top만큼 모자라 스티키가 덜 붙는다.
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.size.height, initial: true) { _, height in
                            scrollViewHeight = height
                        }
                }
                .ignoresSafeArea(edges: .top)
            )

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
        // 스크롤 반응형 네비 타이틀 — 좌우 버튼(44pt)과 겹치지 않게 여백 후 말줄임.
        .overlay {
            Text(novelTitle)
                .applyWSSFont(.title2)
                .foregroundStyle(Color.wssBlack)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 44)
                .opacity(showNavTitle ? 1 : 0)
                .animation(.easeInOut(duration: 0.1), value: showNavTitle)
        }
        .padding(.leading, 6)
        .padding(.trailing, 12)
        // 타이틀과 함께 페이드인하는 흰 배경 — 없으면 타이틀·버튼이 스크롤되는 본문과 겹쳐 안 읽힌다.
        // 네비바 자신은 ZStack 자식이라 이미 안전영역 상단에 붙는다(UIKit `safeAreaLayoutGuide`와 동일).
        // 상태바까지 뚫고 올라가야 하는 건 배경뿐이고, 그건 `ignoresSafeArea`가 알아서 한다 —
        // 안전영역 높이를 읽거나 네비바 높이를 더할 필요가 없다.
        // ⚠️ `padding` 뒤에 붙여야 좌우 끝까지 덮는다.
        // 스티키 탭바의 임계선(네비바 하단 y)도 여기서 얻는다 — 이 배경은 `ignoresSafeArea`로
        // 이미 상태바까지 확장돼 있어 그 **실측 높이**가 곧 "안전영역 top + 네비바 높이"다.
        // (안전영역을 직접 읽거나 네비바 높이 44를 더하지 않아도 된다 — 위 주석과 같은 이유.)
        .background(
            GeometryReader { proxy in
                Color.wssWhite
                    .opacity(showNavTitle ? 1 : 0)
                    .animation(.easeInOut(duration: 0.1), value: showNavTitle)
                    .allowsHitTesting(false)  // 네비바 영역에서 시작하는 드래그도 스크롤로 넘긴다.
                    .onChange(of: proxy.size.height, initial: true) { _, height in
                        navigationBarBottomY = height
                    }
            }
            .ignoresSafeArea(edges: .top)
        )
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

    /// 네비 타이틀에 쓸 작품 제목. 관심 토글이 반영되는 state.novel 우선(제목은 불변이라 어느 쪽이든 동일).
    var novelTitle: String {
        viewModel.state.novel?.title ?? viewModel.state.information?.novel.title ?? ""
    }

    /// 조금이라도 위로 스크롤됐는지 — 스크롤 반응형 네비 타이틀 표시 여부.
    /// -1 임계값은 rest 지점(≈0)의 부동소수 지터로 깜빡이지 않게 하는 여유.
    var showNavTitle: Bool {
        viewModel.state.information != nil && scrollOffsetY < -1
    }

    /// 탭 콘텐츠가 확보해야 할 최소 높이 = 스티키 상태에서 탭바 아래 남는 화면 영역.
    /// 이만큼 있으면 어떤 탭으로 바꿔도 스티키 지점까지 스크롤할 여유가 남아 offset 클램프(=화면 튐)가 없다.
    /// 아직 실측 전(0)이면 0 → 최소 높이 제약 없음.
    var tabContentMinHeight: CGFloat {
        max(0, scrollViewHeight - navigationBarBottomY - tabBarHeight)
    }

    /// 스크롤되는 원본 탭바가 네비바 하단까지 올라왔는지 — 상단 오버레이의 스티키 탭바 표시 여부.
    /// 두 좌표 모두 화면 좌상단(상태바 포함) 기준이라 그대로 비교한다.
    /// 임계선을 아직 못 쟀으면(0) 표시하지 않는다.
    var showStickyTabBar: Bool {
        viewModel.state.information != nil
            && navigationBarBottomY > 0
            && tabBarMinY <= navigationBarBottomY
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

// MARK: - Scroll-reactive nav title

/// 스크롤 오프셋 측정용 ScrollView 좌표공간 이름.
private let scrollSpaceName = "novelDetailScroll"

// MARK: - Scroll bounce control

/// 조상 `UIScrollView`의 **상단 over-scroll만** 막는다(하단 bounce는 유지) — 최상단에서
/// 빈 영역까지 끌려가는 걸 막되, 바닥에서의 고무줄 효과는 남긴다.
/// UIKit에서 `scrollViewDidScroll`이 `contentOffset.y < 0`을 0으로 클램프하던 것과 같은 동작을,
/// SwiftUI 위에선 **delegate 교체 대신 KVO**로 건다 — SwiftUI가 소유·재설정하는 delegate를
/// 건드리면 스크롤 내부 동작이 깨질 수 있어서다(발화 시점은 `scrollViewDidScroll`과 동일).
/// ⚠️ 반드시 **스크롤 콘텐츠 내부**에 배치해야(여기선 VStack의 background) UIView의
/// superview 체인이 UIScrollView에 닿는다.
private struct TopBounceDisabler: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    // 삽입 시점엔 superview가 없어 makeUIView에선 못 찾는다 → 레이아웃 후(updateUIView + async)에 건다.
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async { [weak uiView] in
            guard let scrollView = uiView?.enclosingScrollView else { return }
            context.coordinator.clampTop(of: scrollView)
        }
    }

    final class Coordinator {
        private weak var observed: UIScrollView?
        private var observation: NSKeyValueObservation?

        func clampTop(of scrollView: UIScrollView) {
            guard observed !== scrollView else { return }  // 같은 스크롤뷰면 재관찰하지 않는다.
            observed = scrollView
            observation = scrollView.observe(\.contentOffset, options: [.initial, .new]) { scrollView, _ in
                // 상단 rest(0) 위로 넘어가면 즉시 되돌린다 — 하단(양수 방향) bounce는 건드리지 않는다.
                if scrollView.contentOffset.y < 0 {
                    scrollView.contentOffset.y = 0
                }
            }
        }
    }
}

private extension UIView {
    /// superview 체인을 거슬러 올라 가장 가까운 `UIScrollView`를 찾는다.
    var enclosingScrollView: UIScrollView? {
        var current = superview
        while let view = current {
            if let scrollView = view as? UIScrollView { return scrollView }
            current = view.superview
        }
        return nil
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
