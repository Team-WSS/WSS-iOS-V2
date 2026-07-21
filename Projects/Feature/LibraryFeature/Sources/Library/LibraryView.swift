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

    /// 목록 표시 모드 — VM 처리가 필요 없는 순수 표시 상태라 View가 소유한다.
    fileprivate enum DisplayMode {
        case grid
        case list
    }

    // 선언 순서: VM → View 전용 상태 → @Environment → 주입 let
    @State private var viewModel: LibraryViewModel
    @State private var displayMode: DisplayMode = .grid
    @State private var isSortSheetPresented = false
    @State private var isFilterSheetPresented = false
    /// 필터 시트를 열 때 진입할 탭 — 메인 칩에서 해당 탭으로 바로 들어간다.
    @State private var filterSheetTab: LibraryFilterTab = .readingStatus

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
                .presentationDetents([.height(LibrarySortSheet.sheetHeight)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
                // iOS 26 시트 기본 배경은 글래스 — 디자인은 불투명 흰색.
                .presentationBackground(Color.wssWhite)
            }
            .sheet(isPresented: $isFilterSheetPresented) {
                LibraryFilterSheet(
                    filter: viewModel.state.filter,
                    initialTab: filterSheetTab,
                    registeredKeywords: viewModel.state.registeredKeywords
                ) { filter in
                    viewModel.handle(.applyFilter(filter))
                }
                .presentationDetents([.height(LibraryFilterSheet.sheetHeight)])
                .presentationCornerRadius(16)
                // iOS 26 시트 기본 배경은 글래스 — 디자인은 불투명 흰색.
                .presentationBackground(Color.wssWhite)
            }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.requiresAuthentication) { _, required in
                if required { onAuthenticationRequired() }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            headerSection
            controlSection
            countSortSection
            novelListSection
        }
        .background(Color.wssWhite)
        .overlay {
            if viewModel.state.loadFailed {
                NetworkErrorView { viewModel.handle(.retry) }
                    .background(Color.wssWhite)
            }
        }
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
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 40)
    }

    /// 그리드/리스트 모드 토글 + 필터 칩 행(관심 + 시트 필터 6종).
    var controlSection: some View {
        HStack(spacing: 12) {
            displayModeToggle
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
    var novelListSection: some View {
        ScrollView {
            if viewModel.state.isLoading {
                LoadingView()
                    .frame(minHeight: 400)
            } else if viewModel.state.novels.isEmpty {
                emptySection
            } else {
                VStack(spacing: 0) {
                    Spacer().frame(height: 12)
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
            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
            spacing: 18
        ) {
            ForEach(viewModel.state.novels, id: \.id) { novel in
                Button {
                    onNovelSelected(novel.id)
                } label: {
                    LibraryGridCell(novel: novel)
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
                        .padding(.horizontal, 20)
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

// MARK: - Controls

private extension LibraryView {

    /// 그리드/리스트 보기 방식 미니 세그먼트 — 선택 세그먼트만 흰 배경 + 그림자.
    var displayModeToggle: some View {
        HStack(spacing: 2) {
            displayModeSegment(.grid) {
                gridIcon(color: displayMode == .grid ? Color.wssBlack : Color.wssGray100)
            }
            displayModeSegment(.list) {
                listIcon(color: displayMode == .list ? Color.wssBlack : Color.wssGray100)
            }
        }
        .padding(3)
        .background(Color.wssGray20)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.wssGray70, lineWidth: 1))
    }

    func displayModeSegment(_ mode: DisplayMode, @ViewBuilder icon: () -> some View) -> some View {
        Button {
            displayMode = mode
        } label: {
            icon()
                .frame(width: 31, height: 26)
                .background(displayMode == mode ? Color.wssWhite : Color.clear)
                .clipShape(Capsule())
                .shadow(
                    color: displayMode == mode ? Color.wssBlack.opacity(0.12) : .clear,
                    radius: 2, y: 1
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.1), value: displayMode == mode)
    }

    func gridIcon(color: Color) -> some View {
        VStack(spacing: 2) {
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 2) {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
    }

    func listIcon(color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color)
                        .frame(width: 2, height: 2)
                    Capsule()
                        .fill(color)
                        .frame(width: 7, height: 2)
                }
            }
        }
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
            filterSheetTab = tab
            viewModel.handle(.loadRegisteredKeywords)
            isFilterSheetPresented = true
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
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.wssBlack : Color.wssGray80, lineWidth: 1)
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
            return status == .onGoing ? "연재중" : "완결작"
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
