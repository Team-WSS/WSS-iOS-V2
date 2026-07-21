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

    /// 매력포인트 표시 순서(디자인 정본) — `AttractivePoint.allCases` 순서와 다르다(필력이 3번째).
    private static let attractivePointOrder: [AttractivePoint] = [
        .worldview, .material, .writingSkill, .character, .relationship, .vibe
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
            Rectangle()
                .fill(Color.wssGray50)
                .frame(height: 1)
            Spacer().frame(height: 16)
            tabContentSection
            Spacer()
            ctaSection
        }
    }
}

// MARK: - Sections

private extension LibraryFilterSheet {

    var headerSection: some View {
        HStack(spacing: 0) {
            Text("작품 찾기 필터")
                .applyWSSFont(.body2, color: .wssGray200)
            Spacer()
            Button {
                dismiss()
            } label: {
                WSSImage.icCancelModal.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    /// 탭 라벨 + 밑줄(선택) + 보라 점(그 탭에 활성 필터 있음).
    /// 6탭이 화면 폭보다 넓어 가로 스크롤(디자인도 우측 탭이 잘려 있음).
    var tabSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(LibraryFilterTab.allCases, id: \.self) { tab in
                    tabItem(tab)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    func tabItem(_ tab: LibraryFilterTab) -> some View {
        let isSelected = viewModel.state.selectedTab == tab
        return Button {
            viewModel.handle(.selectTab(tab))
        } label: {
            HStack(alignment: .top, spacing: 3) {
                VStack(spacing: 0) {
                    Text(tabTitle(tab))
                        .applyWSSFont(.title2, color: isSelected ? .wssBlack : .wssGray300)
                        .fixedSize()
                        .padding(.bottom, 8)
                }
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle().fill(Color.wssBlack).frame(height: 2)
                    }
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

    /// 선택된 필터 전체를 제거형 칩으로 — 없으면 빈 높이 유지(레이아웃 점프 방지, 디자인도 행 고정).
    var chipSection: some View {
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
        .frame(height: 60)
    }

    @ViewBuilder
    var tabContentSection: some View {
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
                        .fill(Color.wssGray50)
                        .frame(width: 1, height: 40)
                }
                readingStatusItem(status)
            }
        }
        .padding(.horizontal, 20)
    }

    func readingStatusItem(_ status: ReadingStatus) -> some View {
        let isSelected = viewModel.state.filter.readingStatus.contains(status)
        return Button {
            viewModel.handle(.toggleReadingStatus(status))
        } label: {
            VStack(spacing: 4) {
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
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }

    var genreContent: some View {
        WSSFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
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
            HStack(spacing: 0) {
                ratingValueBox(viewModel.state.ratingMin)
                Spacer().frame(width: 16)
                LibraryRatingSlider(
                    min: viewModel.state.ratingMin,
                    max: viewModel.state.ratingMax,
                    isDisabled: viewModel.isUnratedOnly
                ) { min, max in
                    viewModel.handle(.changeRatingRange(min: min, max: max))
                }
                Spacer().frame(width: 16)
                ratingValueBox(viewModel.state.ratingMax)
            }
            Spacer().frame(height: 16)
            HStack(spacing: 0) {
                Text("별점 등록 안된 작품만 보기")
                    .applyWSSFont(.title2, color: .wssGray300)
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
            ForEach(Self.attractivePointOrder, id: \.self) { point in
                attractivePointItem(point)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }

    func attractivePointItem(_ point: AttractivePoint) -> some View {
        let isSelected = viewModel.state.filter.attractivePoint.contains(point)
        return Button {
            viewModel.handle(.toggleAttractivePoint(point))
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
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }

    /// 키워드 — 내가 서재 작품에 등록한 키워드에서 고른다.
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
                Spacer().frame(height: 12)
                ScrollView(.vertical, showsIndicators: false) {
                    WSSFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                        ForEach(registeredKeywords) { keyword in
                            CapsuleSelectableKeywordChip(
                                keyword: keyword.name,
                                isSelected: viewModel.state.filter.keywords.contains(keyword)
                            ) {
                                viewModel.handle(.toggleKeyword(keyword))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    /// 초기화(시트 필터만 리셋, 시트 유지) + 작품 찾기(적용 후 닫기).
    var ctaSection: some View {
        HStack(spacing: 0) {
            Button {
                viewModel.handle(.clearAll)
            } label: {
                HStack(spacing: 4) {
                    WSSImage.icReset.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("초기화")
                        .applyWSSFont(.title2, color: .wssGray200)
                }
                .frame(width: 95, height: 53)
                .background(Color.wssWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.wssGray80, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

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
        case .rating(.range(let min, let max)):
            return String(format: "%.1f~%.1f", min, max)
        case .rating(.unratedOnly):
            return "별점 없음"
        case .attractivePoint(let point):
            return point.displayName
        case .keyword(let keyword):
            return keyword.name
        }
    }
}

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
