//
//  LibraryView.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import DesignSystem
import WSSComponent

// 서재 탭 — 내가 등록한 작품 목록을 그리드/리스트로 조회하고 필터·정렬한다.
// "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
struct LibraryView: View {

    // 선언 순서: VM → View 전용 상태 → @Environment → 주입 let
    @State private var viewModel: LibraryViewModel
    /// 목록 표시 모드 — VM 처리가 필요 없는 순수 표시 상태라 View가 소유한다(타입은 타유저 서재와 공유).
    @State private var displayMode: LibraryDisplayMode = .grid
    @State private var isSortSheetPresented = false
    /// 필터 시트를 열 때 진입할 탭 — 메인 칩에서 해당 탭으로 바로 들어간다. non-nil이 곧 "시트 열림"이다.
    /// ⚠️ `isPresented` + 별도 탭 State 조합이면 **첫 진입에서만** 탭이 무시된다(아래 `.sheet(item:)` 주석 참고).
    @State private var filterSheetTab: LibraryFilterTab?

    /// 작품 셀 탭 → 작품 상세 진입 콜백. 화면 전환은 호출자(App)가 수행한다.
    private let onNovelSelected: (NovelID) -> Void
    /// 빈 상태 "웹소설 찾기" 버튼 → 검색 화면 진입 콜백.
    private let onSearchTapped: () -> Void
    /// 우상단 등록 버튼 → 작품 등록(검색) 진입 콜백.
    private let onRegisterTapped: () -> Void
    /// "알림 관리" → 관심 작품 알림 설정 진입 콜백.
    private let onNotificationTapped: () -> Void
    /// 인증 만료 시 로그인 유도 콜백 — 화면 내 모든 서버 호출 공통.
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: LibraryViewModel,
        onNovelSelected: @escaping (NovelID) -> Void,
        onSearchTapped: @escaping () -> Void,
        onRegisterTapped: @escaping () -> Void,
        onNotificationTapped: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onNovelSelected = onNovelSelected
        self.onSearchTapped = onSearchTapped
        self.onRegisterTapped = onRegisterTapped
        self.onNotificationTapped = onNotificationTapped
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        content
            .onAppear { viewModel.handle(.load) }
            .sheet(isPresented: $isSortSheetPresented) {
                LibrarySortSheet(selected: viewModel.state.filter.sortType) { sortType in
                    isSortSheetPresented = false
                    viewModel.handle(.selectSortType(sortType))
                }
            }
            // ⚠️ `isPresented:` + 별도 탭 State로 열면 **앱 실행 후 첫 시트만** 기본 탭(읽기상태)으로 열린다 —
            // SwiftUI가 시트 콘텐츠를 미리 평가하며 시트 VM의 `@State` 저장소를 그때의 탭 값으로 만들어버려,
            // 뒤늦게 바뀐 탭이 반영되지 않는다(두 번째부터는 이전 값이 이미 맞아떨어져 정상처럼 보인다).
            // `item:`은 진입 탭이 확정된 뒤 그 값을 인자로 받아 콘텐츠를 만들므로 이 틈이 없다.
            .sheet(item: $filterSheetTab) { tab in
                LibraryFilterSheet(
                    filter: viewModel.state.filter,
                    initialTab: tab,
                    registeredKeywords: viewModel.state.registeredKeywords
                ) { filter in
                    viewModel.handle(.applyFilter(filter))
                }
                .presentationDetents([.height(LibraryFilterSheet.sheetHeight)])
                // iOS 26 시트 기본 배경은 글래스 — 디자인은 불투명 흰색.
                // presentationCornerRadius는 쓰지 않는다(배경이 둥근 모서리에 클립되지 않아 삐져나옴).
                .presentationBackground(Color.wssWhite)
            }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.requiresAuthentication) { _, required in
                guard required else { return }
                onAuthenticationRequired()
                // 신호를 즉시 되돌려야 2회차 만료도 onChange를 다시 발화시킨다(탭이라 VM이 계속 산다).
                viewModel.handle(.consumeAuthenticationRequired)
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            headerSection
            // 첫 페이지 실패는 헤더(타이틀·등록 버튼)만 남기고 그 아래를 전면 실패 뷰로 대체한다 —
            // 필터/정렬/카운트는 실패 상태에서 조작할 게 없어 함께 숨긴다.
            if viewModel.state.loadFailed {
                NetworkErrorView { viewModel.handle(.retry) }
            } else {
                controlSection
                countSortSection
                novelListSection
            }
        }
        .background(Color.wssWhite)
    }
}

// MARK: - Sections

private extension LibraryView {

    /// 상단 헤더 — "서재" 타이틀 + 작품 등록 버튼.
    var headerSection: some View {
        HStack(spacing: 0) {
            Text("서재")
                .applyWSSFont(.headline1, color: .wssBlack)
            Spacer()
            Button {
                onRegisterTapped()
            } label: {
                WSSImage.icBookRegister.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    // 아이콘 24는 그대로는 잡기 어려워 주변으로만 히트 영역을 넓힌다(좌 10 · 상하 8).
                    // 우측은 헤더 패딩 20이 이미 여백이라 더 주지 않는다 — 주면 그만큼 아이콘이 왼쪽으로 밀린다.
                    .padding(.leading, 10)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 40)
    }

    /// 그리드/리스트 모드 토글 + 필터 칩 행(관심 + 시트 필터 6종).
    var controlSection: some View {
        HStack(spacing: 0) {
            displayModeToggle
            Spacer().frame(width: 12)
            Rectangle()
                .fill(Color.wssGray70)
                .frame(width: 1, height: 29)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    interestChip
                    ForEach(LibraryFilterTab.allCases, id: \.self) { tab in
                        filterChip(tab)
                    }
                }
            }
            // 스크롤 영역은 divider에 바로 붙이고(칩이 divider에서 곧장 잘린다), 첫 칩과의 간격 12·
            // 마지막 칩 뒤 여백 20은 **콘텐츠 마진**으로 준다.
            // 이걸 Spacer/패딩으로 주면 스크롤 영역 자체가 그만큼 좁아져, 왼쪽은 divider에서 떨어진 자리에서
            // 오른쪽은 화면 끝보다 일찍 칩이 잘린다.
            .contentMargins(.leading, 12, for: .scrollContent)
            .contentMargins(.trailing, 20, for: .scrollContent)
        }
        .padding(.leading, 20)
        .frame(height: 50)
    }

    /// 카운트 + 알림 관리 + 정렬.
    var countSortSection: some View {
        HStack(spacing: 0) {
            Text("\(viewModel.state.totalCount)개")
                .applyWSSFont(.body4, color: .wssGray200)
            Spacer()
            Button {
                onNotificationTapped()
            } label: {
                HStack(spacing: 4) {
                    WSSImage.icAlarm.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 15)
                    Text("알림 관리")
                        .applyWSSFont(.body3, color: .wssGray300)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer().frame(width: 10)
            Rectangle()
                .fill(Color.wssGray70)
                .frame(width: 1, height: 8)
            Spacer().frame(width: 10)
            Button {
                isSortSheetPresented = true
            } label: {
                HStack(spacing: 4) {
                    WSSImage.icSwitch.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(viewModel.state.filter.sortType.libraryShortDisplayName)
                        .applyWSSFont(.body3, color: .wssGray300)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 40)
    }

    /// 작품 목록 — 그리드/리스트 모드, 무한 스크롤, 빈 상태.
    @ViewBuilder
    var novelListSection: some View {
        if viewModel.state.isLoading {
            ScrollView {
                LoadingView()
                    .frame(minHeight: 400)
            }
        } else if viewModel.state.novels.isEmpty {
            ScrollView {
                // 서재 자체가 빈 것과 필터로 걸러져 0건인 것은 필요한 행동이 다르다
                // ("웹소설 찾기" vs "필터 완화").
                if hasAnyFilter {
                    noMatchSection
                } else {
                    emptySection
                }
            }
        } else {
            // 두 모드가 **각자의 스크롤 위치**를 지키려면 두 목록이 동시에 살아 있어야 한다.
            // (스크롤 뷰 하나 안에서 콘텐츠만 갈아끼우면 contentOffset이 공유돼 한쪽에서 내린 만큼
            //  다른 쪽도 내려가 있다 — 실제 증상.)
            ZStack {
                novelScroll(for: .grid) { gridList }
                novelScroll(for: .list) { rowList }
            }
        }
    }

    /// 모드별 목록 스크롤 — 안 보이는 쪽도 **지우지 않고 숨기기만** 한다(스크롤 위치 보존).
    /// 살아 있는 채 겹쳐 있으므로 탭·VoiceOver가 새지 않게 함께 막는다.
    /// ⚠️ 숨은 쪽의 `loadMore`(마지막 셀 onAppear)는 막지 않는다 — 모드로 가드하면 그 셀이 이미
    /// onAppear를 소진해, 나중에 그 모드로 전환했을 때 무한 스크롤이 되살아나지 않는다.
    /// 중복 요청은 VM이 흡수한다 — 진행 중이면 드롭하고, 갱신에 밀린 경우만 예약해 뒤이어 실행한다.
    func novelScroll(for mode: LibraryDisplayMode, @ViewBuilder list: () -> some View) -> some View {
        let isVisible = displayMode == mode
        return ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 12)
                list()
                if viewModel.state.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, 16)
                }
                Spacer().frame(height: 24)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
    }

    var gridList: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
            spacing: 18
        ) {
            ForEach(viewModel.state.novels, id: \.id) { novel in
                Button {
                    onNovelSelected(novel.id)
                } label: {
                    LibraryGridCell(novel: novel)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onAppear { loadMoreIfLast(novel) }
            }
        }
        .padding(.horizontal, 20)
    }

    var rowList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.state.novels, id: \.id) { novel in
                Button {
                    onNovelSelected(novel.id)
                } label: {
                    LibraryListCell(novel: novel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onAppear { loadMoreIfLast(novel) }

                Spacer().frame(height: 16)
                Rectangle()
                    .fill(Color.wssGray50)
                    .frame(height: 1)
                Spacer().frame(height: 28)
            }
        }
    }

    /// 관심·시트 필터 6종 중 하나라도 걸려 있는지 — 빈 상태 카피를 가르는 기준.
    /// (정렬은 결과 개수를 바꾸지 않으므로 필터로 치지 않는다.)
    var hasAnyFilter: Bool {
        viewModel.state.filter.hasActiveSheetFilter || viewModel.state.filter.isInterest
    }

    /// 필터 결과 0건 — 서재는 비어있지 않으므로 "웹소설 찾기" 대신 범위를 넓히라고 안내한다.
    var noMatchSection: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 120)
            WSSImage.imgEmpty.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 39, height: 48)
            Spacer().frame(height: 8)
            Text("해당하는 작품이 없어요\n검색의 범위를 더 넓혀보세요")
                .applyWSSFont(.body1, color: .wssGray200)
        }
        .frame(maxWidth: .infinity)
    }

    /// 빈 상태 — "서재가 비어있어요" + 웹소설 찾기.
    var emptySection: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 120)
            WSSImage.imgEmpty.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 39, height: 48)
            Spacer().frame(height: 8)
            Text("서재가 비어있어요")
                .applyWSSFont(.body1, color: .wssGray200)
            Spacer().frame(height: 45)
            Button {
                onSearchTapped()
            } label: {
                Text("웹소설 찾기")
                    .applyWSSFont(.title1, color: .wssPrimary100)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.wssPrimary50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 90)
        }
        .frame(maxWidth: .infinity)
    }
}

// 화면 전용 컨트롤(모드 토글·필터 칩) — Sections가 조립하는 leaf들.
private extension LibraryView {

    private enum ToggleMetric {
        static let segmentWidth: CGFloat = 31
        static let segmentHeight: CGFloat = 26
        static let spacing: CGFloat = 2
        /// 리스트 선택 시 흰 원이 오른쪽 세그먼트로 미끄러지는 거리 = 세그먼트 폭 + 세그먼트 간격.
        static var knobSlide: CGFloat { segmentWidth + spacing }
    }

    /// 그리드/리스트 보기 방식 미니 세그먼트 — 선택 표시인 흰 원 하나가 좌↔우로 미끄러진다(토글 스위치 느낌).
    var displayModeToggle: some View {
        HStack(spacing: ToggleMetric.spacing) {
            displayModeSegment(.grid) {
                LibraryDisplayModeIcon(mode: .grid, color: displayMode == .grid ? .wssBlack : .wssGray100)
            }
            displayModeSegment(.list) {
                LibraryDisplayModeIcon(mode: .list, color: displayMode == .list ? .wssBlack : .wssGray100)
            }
        }
        // 흰 원 하나를 항상 그려두고 x offset만 바꿔 대놓고 미끄러뜨린다.
        // (조건부 insert/remove + matchedGeometry는 이동이 아니라 크로스페이드로 보여서 버림.)
        .background(alignment: .leading) {
            Capsule()
                .fill(Color.wssWhite)
                .shadow(color: Color.wssBlack.opacity(0.12), radius: 2, y: 1)
                .frame(width: ToggleMetric.segmentWidth, height: ToggleMetric.segmentHeight)
                .offset(x: displayMode == .grid ? 0 : ToggleMetric.knobSlide)
        }
        .padding(3)
        .background(Color.wssGray20)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.wssGray70, lineWidth: 1))
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: displayMode)
    }

    func displayModeSegment(_ mode: LibraryDisplayMode, @ViewBuilder icon: () -> some View) -> some View {
        Button {
            displayMode = mode
        } label: {
            icon()
                .frame(width: ToggleMetric.segmentWidth, height: ToggleMetric.segmentHeight)
                .contentShape(Capsule())
        }
        // 아이콘만 있는 버튼이라 `.buttonStyle(.plain)`을 빼야 눌린 게 보인다(Feature 규칙) —
        // 이미 선택된 세그먼트를 눌렀을 때 아무 반응이 없던 원인.
    }

    /// 관심 칩 — 시트 없이 즉시 토글.
    var interestChip: some View {
        chipLabel(
            title: "관심",
            isSelected: viewModel.state.filter.isInterest,
            showsDropdownIcon: false
        ) {
            viewModel.handle(.toggleInterestFilter)
        }
    }

    /// 시트 필터 칩 — 탭하면 해당 탭으로 필터 시트를 연다.
    func filterChip(_ tab: LibraryFilterTab) -> some View {
        chipLabel(
            title: chipSummary(tab),
            isSelected: hasActiveFilter(tab),
            showsDropdownIcon: true
        ) {
            viewModel.handle(.loadRegisteredKeywords)
            // 탭을 넣는 것이 곧 시트 열기(`.sheet(item:)`).
            filterSheetTab = tab
        }
    }

    func chipLabel(
        title: String,
        isSelected: Bool,
        showsDropdownIcon: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text(title)
                    .applyWSSFont(.body5, color: isSelected ? .wssWhite : .wssGray300)
                if showsDropdownIcon {
                    WSSImage.icDropdownfill.swiftUIImage
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .foregroundStyle(isSelected ? Color.wssWhite : Color.wssGray80)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, showsDropdownIcon ? 8 : 12)
            .frame(height: 30)
            .background(isSelected ? Color.wssBlack : Color.wssWhite)
            .clipShape(Capsule())
            // strokeBorder(= 안쪽으로 그림). stroke면 선의 절반이 프레임 밖으로 나가 가로 ScrollView 클립에 잘린다.
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.wssBlack : Color.wssGray80, lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

// MARK: - Presentation

private extension LibraryView {

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedToast != nil },
            set: { if !$0 { viewModel.handle(.dismissToast) } }
        )
    }

    var toastType: WSSToastType {
        // 더보기·키워드 실패 모두 네트워크 실패 계열 — 정본(NovelDetail)과 동일하게 unknownError 하나로 표현(의도).
        .unknownError
    }

    func loadMoreIfLast(_ novel: LibraryNovel) {
        if novel.id == viewModel.state.novels.last?.id {
            viewModel.handle(.loadMore)
        }
    }

    func hasActiveFilter(_ tab: LibraryFilterTab) -> Bool {
        let filter = viewModel.state.filter
        switch tab {
        case .readingStatus:     return !filter.readingStatus.isEmpty
        case .genre:             return !filter.genres.isEmpty
        case .publicationStatus: return filter.publicationStatus != nil
        case .rating:            return filter.rating != nil
        case .attractivePoint:   return !filter.attractivePoint.isEmpty
        case .keyword:           return !filter.keywords.isEmpty
        }
    }

    /// 칩 요약 카피 — 미선택은 필터명, 단일 선택은 값, 복수 선택은 "첫 값 외 N".
    func chipSummary(_ tab: LibraryFilterTab) -> String {
        let filter = viewModel.state.filter
        switch tab {
        case .readingStatus:
            return summary(values: filter.readingStatus.map(\.statusName), fallback: "읽기상태")
        case .genre:
            return summary(values: filter.genres.map(\.displayName), fallback: "장르")
        case .publicationStatus:
            guard let status = filter.publicationStatus else { return "연재상태" }
            return status.libraryDisplayName
        case .rating:
            switch filter.rating {
            case .range(let min, let max): return String(format: "%.1f~%.1f", min, max)
            case .unratedOnly:             return "별점 없음"
            case nil:                      return "별점"
            }
        case .attractivePoint:
            return summary(values: filter.attractivePoint.map(\.displayName), fallback: "매력포인트")
        case .keyword:
            return summary(values: filter.keywords.map(\.name), fallback: "키워드")
        }
    }

    func summary(values: [String], fallback: String) -> String {
        guard let first = values.first else { return fallback }
        return values.count == 1 ? first : "\(first) 외 \(values.count - 1)"
    }
}

// MARK: - Preview

#Preview {
    LibraryView(
        viewModel: LibraryViewModel(
            loadMyLibraryUseCase: PreviewLoadMyLibraryUseCase(),
            loadMyLibraryKeywordsUseCase: PreviewLoadMyLibraryKeywordsUseCase()
        ),
        onNovelSelected: { print("작품 상세: \($0)") },
        onSearchTapped: { print("웹소설 찾기") },
        onRegisterTapped: { print("작품 등록") },
        onNotificationTapped: { print("알림 관리") },
        onAuthenticationRequired: { print("로그인 유도") }
    )
}

private struct PreviewLoadMyLibraryUseCase: LoadMyLibraryUseCase {
    func execute(
        filter: MyLibraryFilter,
        cursor: String?,
        size: Int
    ) async throws(RepositoryError) -> (CursorPaginated<LibraryNovel>, Int) {
        let novels = (1...6).map { index in
            LibraryNovel(
                id: NovelID(index),
                title: "미리보기 작품 \(index)",
                thumbnailImage: nil,
                rating: 4.2,
                isInterested: index.isMultiple(of: 2),
                userReview: UserNovelReview(
                    readingStatus: .watching,
                    rating: try? Rating(4.0),
                    attractivePoint: [.character],
                    period: nil,
                    keywords: []
                ),
                writtenFeeds: []
            )
        }
        return (CursorPaginated(items: novels, hasNext: false, nextCursor: nil), novels.count)
    }
}

private struct PreviewLoadMyLibraryKeywordsUseCase: LoadMyLibraryKeywordsUseCase {
    func execute() async throws(RepositoryError) -> [Keyword] {
        [Keyword(id: KeywordID(1), name: "빙의")]
    }
}
