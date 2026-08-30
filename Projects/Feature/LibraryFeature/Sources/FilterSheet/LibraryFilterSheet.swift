//
//  LibraryFilterSheet.swift
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

// 필터 바텀시트 — 6탭(읽기상태·장르·연재상태·별점·매력포인트·키워드) + 선택 칩 행 + 초기화/작품 찾기.
// 결과 발화는 View가 한다: "작품 찾기" = 편집한 필터를 onApply로 부모에 올리면 부모가 적용 + dismiss.
//
// 레이아웃 골격은 구 WSSiOS `LibraryFilterView`(UIKit) 정본을 따른다 —
// 헤더 / 탭바(h30) / 선택 칩 행(있을 때만) / 탭 콘텐츠(남은 공간 전부 + 세로 스크롤) / 하단 액션바.
// 탭마다 콘텐츠 높이가 크게 다르므로 **콘텐츠 영역이 남은 공간을 전부 차지**하는 게 핵심이다.
struct LibraryFilterSheet: View {

    @State private var viewModel: LibraryFilterSheetViewModel
    @Environment(\.dismiss) private var dismiss
    /// 키워드 탭 데이터 — 부모 VM이 로드해 내려준다(시트는 서버를 모른다).
    private let registeredKeywords: [Keyword]
    private let onApply: (MyLibraryFilter) -> Void

    static let sheetHeight: CGFloat = 516

    /// 서재 필터 시트의 장르 표시 순서(디자인 정본) — 검색 필터의 `filterGenre` 순서와 다르다.
    private static let genreOrder: [NovelGenre] = [
        .fantasy, .modernFantasy, .romance, .romanceFantasy, .wuxia,
        .mystery, .drama, .lightNovel, .BL
    ]

    init(
        filter: MyLibraryFilter,
        initialTab: LibraryFilterTab,
        registeredKeywords: [Keyword],
        onApply: @escaping (MyLibraryFilter) -> Void
    ) {
        self._viewModel = State(initialValue: LibraryFilterSheetViewModel(filter: filter, initialTab: initialTab))
        self.registeredKeywords = registeredKeywords
        self.onApply = onApply
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            tabSection
            chipSection
            Spacer().frame(height: 16)
            tabContentSection
            ctaSection
        }
    }
}

// MARK: - Sections

private extension LibraryFilterSheet {

    /// 헤더 — 타이틀 + 닫기. 닫기는 레이아웃에 영향을 주지 않도록 overlay로 얹는다(정본도 타이틀 높이만 차지).
    var headerSection: some View {
        Text("작품 찾기 필터")
            .applyWSSFont(.body2, color: .wssGray200)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .padding(.top, 20)
            .padding(.bottom, 18)
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    WSSImage.icCancelModal.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        // 아이콘이 작아 그대로는 잡기 어렵다 — 정본과 같은 65 히트 영역.
                        .frame(width: 65, height: 65)
                        .contentShape(Rectangle())
                }
                // 아이콘만 있는 버튼이라 `.buttonStyle(.plain)`을 빼야 눌린 게 보인다(Feature 규칙).
            }
    }

    /// 탭 라벨 + 밑줄(선택) + 보라 점(그 탭에 활성 필터 있음).
    /// 6탭이 화면 폭보다 넓어 가로 스크롤(디자인도 우측 탭이 잘려 있음).
    var tabSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(LibraryFilterTab.allCases, id: \.self) { tab in
                    tabItem(tab)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 30)
    }

    func tabItem(_ tab: LibraryFilterTab) -> some View {
        let isSelected = viewModel.state.selectedTab == tab
        return Button {
            viewModel.handle(.selectTab(tab))
        } label: {
            HStack(alignment: .top, spacing: 3) {
                Text(tabTitle(tab))
                    .applyWSSFont(.title2, color: isSelected ? .wssBlack : .wssGray300)
                    .fixedSize()
                    // 라벨 아래 6 + 밑줄 2(정본 수치).
                    .padding(.bottom, 8)
                    .overlay(alignment: .bottom) {
                        // if로 넣고 빼면 탭 전환마다 라벨 높이가 흔들린다 — 항상 그리고 opacity만 바꾼다.
                        Rectangle()
                            .fill(Color.wssBlack)
                            .frame(height: 2)
                            .opacity(isSelected ? 1 : 0)
                    }
                Circle()
                    .fill(Color.wssPrimary100)
                    .frame(width: 4, height: 4)
                    .opacity(viewModel.hasActiveFilter(in: tab) ? 1 : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }

    /// 선택된 필터 전체를 제거형 칩으로. 칩이 없으면 구분선까지 통째로 사라진다(정본 동작) —
    /// 빈 자리를 남기지 않아도 아래 콘텐츠 영역이 늘어나 흡수하므로 레이아웃이 튀지 않는다.
    @ViewBuilder
    var chipSection: some View {
        if !viewModel.chips.isEmpty {
            Spacer().frame(height: 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(viewModel.chips, id: \.self) { chip in
                        WhiteRemovableKeywordChip(keyword: chipTitle(chip)) {
                            viewModel.handle(.removeChip(chip))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 35)
            Spacer().frame(height: 12)
            Rectangle()
                .fill(Color.wssGray50)
                .frame(height: 1)
        }
    }

    /// 탭 콘텐츠 — 공통 세로 스크롤은 두지 않는다. 현재 탭 중 키워드만 가변 길이라,
    /// 키워드 칩 영역만 자체 스크롤하고(`keywordContent`) 나머지 탭은 고정 콘텐츠로 둔다.
    /// 남은 공간을 전부 차지해야 탭 전환 때 콘텐츠가 위아래로 튀지 않는다.
    var tabContentSection: some View {
        tabContent
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    var tabContent: some View {
        switch viewModel.state.selectedTab {
        case .readingStatus:     readingStatusContent
        case .genre:             genreContent
        case .publicationStatus: publicationStatusContent
        case .rating:            ratingContent
        case .attractivePoint:   attractivePointContent
        case .keyword:           keywordContent
        }
    }

    /// 읽기상태 — 3분할, 사이 세로 구분선. 선택 시 아이콘·라벨 보라.
    var readingStatusContent: some View {
        HStack(spacing: 0) {
            ForEach(Array(ReadingStatus.allCases.enumerated()), id: \.element) { index, status in
                if index > 0 {
                    Rectangle()
                        .fill(Color.wssGray70)
                        .frame(width: 1, height: 32)
                }
                readingStatusItem(status)
            }
        }
        .frame(height: 54)
        .padding(.horizontal, 20)
    }

    /// 선택 칩 행이 생기거나 사라져 **레이아웃이 바뀌는** 액션은 애니메이션 트랜잭션 자체를 꺼서 반영한다.
    /// ⚠️ 뷰에서 `.animation` modifier를 떼는 것만으론 부족하다 — 액션 시점 트랜잭션이 살아 있으면
    /// 칩 행 등장/제거로 밀리는 레이아웃이 그대로 애니메이트돼, **방금 누른 항목만** 뒤늦게 따라온다.
    func handleWithoutAnimation(_ action: LibraryFilterSheetViewModel.Action) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            viewModel.handle(action)
        }
    }

    /// 읽기상태 항목 — 선택 시 아이콘 fill + 보라. **색 전환 애니메이션 없이 즉시** 반영한다(`handleWithoutAnimation`).
    /// ⚠️ #221에서 "색만 애니메이트 + 위치는 스냅"을 시도했다가 **사용자 결정으로 걷어냈다** — 이 항목의 아이콘은
    /// ① 템플릿 tint라 `foregroundStyle` 색이 `.animation`으로 보간되지 않고 스냅하고(칩이 되는 건 `.background`라서),
    /// ② `Button`이라 `.animation(value:)`를 라벨 안에 걸어야만 먹는 등 함정이 겹쳐 opacity 크로스페이드까지 동원해야
    /// 했는데, 그만한 값어치가 없다고 판단해 **즉시 전환으로 되돌렸다.** 되살릴 거면 이 모듈 CLAUDE.md의 그 항목부터 읽을 것.
    func readingStatusItem(_ status: ReadingStatus) -> some View {
        let isSelected = viewModel.state.filter.readingStatus.contains(status)
        return Button {
            handleWithoutAnimation(.toggleReadingStatus(status))
        } label: {
            VStack(spacing: 5) {
                (isSelected ? status.fillImage : status.strokeImage)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isSelected ? Color.wssPrimary100 : Color.wssGray100)
                Text(status.statusName)
                    .applyWSSFont(.body4, color: isSelected ? .wssPrimary100 : .wssGray300)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var genreContent: some View {
        WSSFlowLayout(horizontalSpacing: 6, verticalSpacing: 14) {
            ForEach(Self.genreOrder, id: \.self) { genre in
                CapsuleSelectableKeywordChip(
                    keyword: genre.displayName,
                    isSelected: viewModel.state.filter.genres.contains(genre)
                ) {
                    viewModel.handle(.toggleGenre(genre))
                }
            }
        }
        .padding(.horizontal, 20)
    }

    var publicationStatusContent: some View {
        HStack(spacing: 0) {
            ForEach(Array([NovelPublicationStatus.onGoing, .completed].enumerated()), id: \.element) { index, status in
                if index > 0 {
                    Spacer().frame(width: 11)
                }
                RectangleSelectableKeywordChip(
                    keyword: status.libraryDisplayName,
                    isSelected: viewModel.state.filter.publicationStatus == status
                ) {
                    viewModel.handle(.togglePublicationStatus(status))
                }
            }
        }
        .padding(.horizontal, 20)
    }

    /// 별점 — 범위 슬라이더 + "별점 등록 안된 작품만 보기" 토글.
    var ratingContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 10)
            HStack(spacing: 0) {
                ratingValueBox(viewModel.state.ratingMin)
                Spacer().frame(width: 17)
                WSSRangeSlider(
                    min: viewModel.state.ratingMin,
                    max: viewModel.state.ratingMax,
                    isDisabled: viewModel.isUnratedOnly
                ) { min, max in
                    viewModel.handle(.changeRatingRange(min: min, max: max))
                }
                Spacer().frame(width: 17)
                ratingValueBox(viewModel.state.ratingMax)
            }
            Spacer().frame(height: 28)
            HStack(spacing: 0) {
                Text("별점 등록 안된 작품만 보기")
                    .applyWSSFont(.body2, color: .wssGray300)
                Spacer()
                WSSToggleButton(isOn: unratedOnlyBinding)
            }
        }
        .padding(.horizontal, 20)
    }

    func ratingValueBox(_ value: Float) -> some View {
        Text(String(format: "%.1f", value))
            .applyWSSFont(.body2, color: viewModel.isUnratedOnly ? .wssGray200 : .wssPrimary100)
            .frame(width: 50, height: 38)
            .background(Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// 매력포인트 — 6개 균등, 아이콘 36 + 라벨. 선택 시 보라.
    var attractivePointContent: some View {
        HStack(spacing: 0) {
            ForEach(AttractivePoint.displayOrder, id: \.self) { point in
                attractivePointItem(point)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 68)
        .padding(.horizontal, 20)
    }

    /// 매력포인트 항목 — 선택 시 보라. 읽기상태와 같은 이유로 **색 애니메이션 없이 즉시** 반영(위 `readingStatusItem` 주석 참고).
    func attractivePointItem(_ point: AttractivePoint) -> some View {
        let isSelected = viewModel.state.filter.attractivePoint.contains(point)
        return Button {
            handleWithoutAnimation(.toggleAttractivePoint(point))
        } label: {
            VStack(spacing: 6) {
                point.iconImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundStyle(isSelected ? Color.wssPrimary100 : Color.wssGray100)
                Text(point.displayName)
                    .applyWSSFont(.body4, color: isSelected ? .wssPrimary100 : .wssGray300)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 키워드 — 카운트는 고정하고, 가변 길이인 칩 영역만 남은 높이 안에서 스크롤한다.
    @ViewBuilder
    var keywordContent: some View {
        if registeredKeywords.isEmpty {
            Text("등록한 키워드가 없습니다.")
                .applyWSSFont(.body4, color: .wssGray200)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("등록한 키워드 \(registeredKeywords.count)개")
                    .applyWSSFont(.body4, color: .wssGray200)
                    .padding(.horizontal, 20)
                Spacer().frame(height: 16)
                ScrollView(.vertical, showsIndicators: false) {
                    WSSFlowLayout(horizontalSpacing: 6, verticalSpacing: 14) {
                        ForEach(registeredKeywords) { keyword in
                            CapsuleSelectableKeywordChip(
                                keyword: keyword.name,
                                isSelected: viewModel.state.filter.keywords.contains(keyword)
                            ) {
                                viewModel.handle(.toggleKeyword(keyword))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    /// 초기화(시트 필터만 리셋, 시트 유지) + 작품 찾기(적용 후 닫기).
    var ctaSection: some View {
        HStack(spacing: 0) {
            WSSResetButton {
                viewModel.handle(.clearAll)
            }

            Spacer().frame(width: 10)

            WSSCTAButton(title: "작품 찾기") {
                onApply(viewModel.state.filter)
                dismiss()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Presentation

private extension LibraryFilterSheet {

    var unratedOnlyBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isUnratedOnly },
            set: { _ in viewModel.handle(.toggleUnratedOnly) }
        )
    }

    func tabTitle(_ tab: LibraryFilterTab) -> String {
        switch tab {
        case .readingStatus:     "읽기상태"
        case .genre:             "장르"
        case .publicationStatus: "연재 상태"
        case .rating:            "별점"
        case .attractivePoint:   "매력포인트"
        case .keyword:           "키워드"
        }
    }

    func chipTitle(_ chip: LibraryFilterSheetViewModel.Chip) -> String {
        switch chip {
        case .readingStatus(let status):
            return status.statusName
        case .genre(let genre):
            return genre.displayName
        case .publicationStatus(let status):
            return status.libraryDisplayName
        case .rating:
            // 별점 칩은 값 없이 하나 — 카피는 현재 필터 값에서 만든다.
            switch viewModel.state.filter.rating {
            case .range(let min, let max): return String(format: "%.1f~%.1f", min, max)
            case .unratedOnly:             return "별점 없음"
            case nil:                      return ""
            }
        case .attractivePoint(let point):
            return point.displayName
        case .keyword(let keyword):
            return keyword.name
        }
    }
}

// MARK: - Selectable Items

// MARK: - Preview

#Preview {
    var filter = MyLibraryFilter()
    filter.addReadingStatus(.watching)
    filter.addAttractivePoint(.writingSkill)
    return LibraryFilterSheet(
        filter: filter,
        initialTab: .attractivePoint,
        registeredKeywords: [
            Keyword(id: KeywordID(1), name: "빙의"),
            Keyword(id: KeywordID(2), name: "후회")
        ]
    ) { print("필터 적용: \($0)") }
}
