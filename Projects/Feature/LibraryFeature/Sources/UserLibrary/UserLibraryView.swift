//
//  UserLibraryView.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import DesignSystem
import WSSComponent

// 타유저 서재 — 다른 사용자가 등록한 작품 목록을 그리드/리스트로 조회한다(정렬만 조절, 필터 없음).
// 내 서재(`LibraryView`)와 셀·정렬 시트를 공유하고, 상단 구성만 다르다.
// "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
struct UserLibraryView: View {

    private enum Metric {
        /// 커스텀 네비게이션 바 높이 — 시스템 네비바(inline)와 같은 44.
        static let navigationBarHeight: CGFloat = 44
        static let backButtonSize: CGFloat = 44
        static let backIconSize: CGFloat = 24
        static let backButtonLeading: CGFloat = 6
        static let countRowHeight: CGFloat = 40
        static let horizontalPadding: CGFloat = 20
        /// 헤더(카운트 행) 아래 목록이 시작되기까지의 간격.
        static let listTopSpacing: CGFloat = 18
        static let gridColumnSpacing: CGFloat = 6
        static let gridRowSpacing: CGFloat = 18
        /// 모드 토글 버튼의 히트 영역 — 아이콘(12)만으론 잡기 어려워 디자인이 33을 잡아뒀다.
        static let displayModeButtonSize: CGFloat = 33
        static let displayModeIconSize: CGFloat = 12
        /// 정렬 버튼 라벨(자연 높이 21)을 카운트 행(40)에 맞추는 세로 여백.
        static let sortButtonVerticalPadding: CGFloat = 9.5
    }

    // 선언 순서: VM → View 전용 상태 → @Environment → 주입 let
    @State private var viewModel: UserLibraryViewModel
    /// 목록 표시 모드 — VM 처리가 필요 없는 순수 표시 상태라 View가 소유한다.
    @State private var displayMode: LibraryDisplayMode = .grid
    @State private var isSortSheetPresented = false
    @Environment(\.dismiss) private var dismiss

    /// 작품 셀 탭 → 작품 상세 진입 콜백. 화면 전환은 호출자(App)가 수행한다.
    private let onNovelSelected: (NovelID) -> Void
    /// 인증 만료 시 로그인 유도 콜백 — 화면 내 모든 서버 호출 공통.
    private let onAuthenticationRequired: () -> Void

    init(
        viewModel: UserLibraryViewModel,
        onNovelSelected: @escaping (NovelID) -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onNovelSelected = onNovelSelected
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    // body = 조립 + 화면 modifier만. 디자인 폰트·뒤로가기 아이콘을 맞추려고 시스템 네비바를 숨기고 커스텀 헤더를 쓴다.
    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            // 네비바를 숨기면 스와이프 뒤로가기까지 함께 꺼진다 → 제스처만 따로 되살린다.
            .background(SwipeBackEnabler())
            .onAppear { viewModel.handle(.load) }
            .sheet(isPresented: $isSortSheetPresented) {
                LibrarySortSheet(selected: viewModel.state.filter.sortType) { sortType in
                    isSortSheetPresented = false
                    viewModel.handle(.selectSortType(sortType))
                }
            }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.requiresAuthentication) { _, required in
                guard required else { return }
                onAuthenticationRequired()
                // 신호를 즉시 되돌린다 — 로그인 화면에서 돌아와 정렬을 바꾸면 이 VM이 그대로 살아 있어
                // true로 굳으면 2회차 만료가 onChange를 다시 발화시키지 못한다.
                viewModel.handle(.consumeAuthenticationRequired)
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            navigationBar
            // 첫 페이지 실패는 네비게이션 바만 남기고 그 아래를 전면 실패 뷰로 대체한다 —
            // 카운트·정렬·모드 토글은 실패 상태에서 조작할 게 없어 함께 숨긴다.
            if viewModel.state.loadFailed {
                NetworkErrorView { viewModel.handle(.retry) }
            } else {
                countSortSection
                Rectangle()
                    .fill(Color.wssGray50)
                    .frame(height: 1)
                novelListSection
            }
        }
        .background(Color.wssWhite)
    }
}

// MARK: - Sections

private extension UserLibraryView {

    /// 커스텀 네비게이션 바 — 뒤로가기 + 중앙 "서재" 타이틀.
    /// 타이틀을 `ZStack` 중앙에 두는 건 의도다 — `HStack`에 넣으면 뒤로가기 버튼 폭만큼 오른쪽으로 밀린다.
    var navigationBar: some View {
        ZStack {
            Text("서재")
                .applyWSSFont(.title2, color: .wssBlack)
            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    WSSImage.icNavigateLeft.swiftUIImage
                        // ⚠️ 이 에셋의 원색은 연회색(#C7C7D0)이라 그대로 쓰면 디자인의 검정 화살표보다 훨씬 흐리다
                        // (DesignSystem CLAUDE.md의 "아이콘 SVG는 원색 고정" 항목) → template으로 색을 입힌다.
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.wssBlack)
                        .frame(width: Metric.backIconSize, height: Metric.backIconSize)
                        // 아이콘 24를 44 히트 영역 가운데 둔다(디자인의 44 탭 타겟).
                        .frame(width: Metric.backButtonSize, height: Metric.backButtonSize)
                        .contentShape(Rectangle())
                }
                Spacer()
            }
            // 디자인의 뒤로가기 버튼은 화면 왼쪽 끝이 아니라 6pt 안쪽에서 시작한다(아이콘 중심 x=28).
            .padding(.leading, Metric.backButtonLeading)
        }
        .frame(height: Metric.navigationBarHeight)
    }

    /// 카운트 + 정렬 + 그리드/리스트 모드 토글.
    var countSortSection: some View {
        HStack(spacing: 0) {
            Text("\(viewModel.state.totalCount)개")
                .applyWSSFont(.body4, color: .wssGray200)
            Spacer()
            sortButton
            Spacer().frame(width: 10)
            displayModeButton
        }
        .padding(.horizontal, Metric.horizontalPadding)
        .frame(height: Metric.countRowHeight)
    }

    var sortButton: some View {
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
            // 라벨 자연 높이가 21뿐이라 contentShape 전에 세로 여백을 줘 카운트 행(40)을 채운다 —
            // 안 주면 그 21pt만 눌린다. (12를 주면 45가 되어 행을 넘는다.)
            .padding(.vertical, Metric.sortButtonVerticalPadding)
            .contentShape(Rectangle())
        }
        // `.buttonStyle(.plain)`을 붙이지 않는다 — `applyWSSFont(_:color:)`가 라벨 안쪽에 foregroundStyle을
        // 명시해 accent 물듦이 애초에 없고(아이콘도 original 렌더링), 붙이면 눌림 피드백만 사라진다.
    }

    /// 모드 토글 — 아이콘 하나가 **지금 보고 있는 모드**를 나타내고, 탭하면 반대 모드로 간다.
    /// (내 서재는 2칸 캡슐 세그먼트라 컨트롤 모양이 다르다 — 디자인이 화면별로 다르게 잡혀 있다.)
    var displayModeButton: some View {
        Button {
            displayMode = displayMode.toggled
        } label: {
            LibraryDisplayModeIcon(mode: displayMode, color: .wssGray100)
                .frame(width: Metric.displayModeIconSize, height: Metric.displayModeIconSize)
                // 아이콘 12는 그대로 잡기 어려워 히트 영역을 33으로 넓힌다(디자인 값).
                .frame(width: Metric.displayModeButtonSize, height: Metric.displayModeButtonSize, alignment: .trailing)
                .contentShape(Rectangle())
        }
        // 라벨이 도형뿐이라 `.buttonStyle(.plain)`을 붙이면 얻는 것 없이 눌림 피드백만 사라진다(Feature 규칙).
        .animation(.easeInOut(duration: 0.1), value: displayMode)
    }

    /// 작품 목록 — 그리드/리스트 모드, 무한 스크롤, 빈 상태.
    @ViewBuilder
    var novelListSection: some View {
        if viewModel.state.isLoading {
            LoadingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.state.novels.isEmpty {
            // 타유저 서재엔 필터가 없으니 "필터로 0건"이 존재하지 않는다 → 빈 상태는 한 가지뿐.
            emptySection
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: Metric.listTopSpacing)
                    switch displayMode {
                    case .grid: gridList
                    case .list: rowList
                    }
                    if viewModel.state.isLoadingMore {
                        ProgressView()
                            .padding(.vertical, 16)
                    }
                    Spacer().frame(height: 24)
                }
            }
        }
    }

    var gridList: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Metric.gridColumnSpacing), count: 3),
            spacing: Metric.gridRowSpacing
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
        .padding(.horizontal, Metric.horizontalPadding)
    }

    var rowList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.state.novels, id: \.id) { novel in
                Button {
                    onNovelSelected(novel.id)
                } label: {
                    LibraryListCell(novel: novel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Metric.horizontalPadding)
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

    /// 빈 상태 — 남의 서재라 "웹소설 찾기" 같은 CTA가 없다(디자인). 남은 공간 가운데에 놓는다.
    var emptySection: some View {
        VStack(spacing: 0) {
            Spacer()
            WSSImage.imgEmpty.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 39, height: 48)
            Spacer().frame(height: 8)
            Text("보관함이 비어있어요")
                .applyWSSFont(.body1, color: .wssGray200)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Presentation

private extension UserLibraryView {

    var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.presentedToast != nil },
            set: { if !$0 { viewModel.handle(.dismissToast) } }
        )
    }

    var toastType: WSSToastType {
        // 더보기 실패는 네트워크 실패 계열 — 내 서재·정본(NovelDetail)과 동일하게 unknownError로 표현(의도).
        .unknownError
    }

    func loadMoreIfLast(_ novel: LibraryNovel) {
        if novel.id == viewModel.state.novels.last?.id {
            viewModel.handle(.loadMore)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserLibraryView(
            viewModel: UserLibraryViewModel(
                userID: UserID(1003),
                loadUserLibraryUseCase: PreviewLoadUserLibraryUseCase()
            ),
            onNovelSelected: { print("작품 상세: \($0)") },
            onAuthenticationRequired: { print("로그인 유도") }
        )
    }
}

private struct PreviewLoadUserLibraryUseCase: LoadUserLibraryUseCase {
    func execute(
        id: UserID,
        filter: LibraryFilter,
        cursor: String?
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
