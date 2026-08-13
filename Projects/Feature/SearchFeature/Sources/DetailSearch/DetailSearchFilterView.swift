//
//  DetailSearchFilterView.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 8/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import SearchDomain
import DesignSystem
import WSSComponent

/// 상세탐색 필터 화면 — "정보"/"키워드" 두 탭이 같은 화면 안에서 콘텐츠만 바뀌는 탭바다.
/// `DetailSearchResultView`의 필터 요약 pill에서 push되고, "작품 찾기" 확정 시 `onSearch`로 편집한 필터를
/// 부모에 올리고 스스로 pop한다(`LibraryFilterSheet`의 `onApply` 패턴과 동일하되, 시트가 아니라 push라
/// dismiss로 되돌아간다). 하단 초기화/작품 찾기 CTA는 **두 탭 공용**이라 탭 전환과 무관하게 항상 보인다.
///
/// ⚠️ "키워드" 탭은 현재 **빈 콘텐츠**다(#185) — 탭 전환 골격만 있고 실제 키워드 선택 UI는 아직 없다.
/// 나중에 채울 것.
struct DetailSearchFilterView: View {

    private enum Tab {
        case info
        case keyword
    }

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DetailSearchFilterViewModel
    @State private var selectedTab: Tab = .info
    /// 플랫폼 옆 안내 아이콘 탭으로 열고 닫는 툴팁(항상 떠 있는 배지 아님) — 사용자 확정.
    @State private var isPlatformBetaTooltipPresented = false
    /// 탭 밑줄이 슬라이드하며 이동하는 애니메이션용 — `FeedFeature`의 `SosoFeedView` 탭바와 동일 패턴
    /// (`matchedGeometryEffect` + 공용 `Namespace`).
    @Namespace private var tabAnimation

    private let onSearch: (SearchFilter) -> Void

    /// Figma 실측 — `WSSComponent.NovelGenre.myFeedFilter`와 노출 순서가 같다(`SearchDomain/CLAUDE.md` 참고).
    private static let genreOrder = NovelGenre.myFeedFilter
    private static let platformOrder = NovelPlatform.allCases
    private static let publicationStatusOrder: [NovelPublicationStatus] = [.onGoing, .completed]

    init(filter: SearchFilter, onSearch: @escaping (SearchFilter) -> Void) {
        self._viewModel = State(initialValue: DetailSearchFilterViewModel(filter: filter))
        self.onSearch = onSearch
    }

    var body: some View {
        VStack(spacing: 0) {
            topBarSection

            Spacer().frame(height: 16)

            tabContent

            ctaSection
        }
        .navigationBarBackButtonHidden()
        .background(Color.wssWhite)
    }
}

// MARK: - Tab Content

private extension DetailSearchFilterView {
    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case .info:
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    genreSection
                    Spacer().frame(height: 40)
                    platformSection
                    Spacer().frame(height: 32)
                    publicationStatusSection
                    Spacer().frame(height: 32)
                    ratingSection
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        case .keyword:
            Spacer()
        }
    }
}

// MARK: - Sections

private extension DetailSearchFilterView {

    /// 뒤로가기 + "정보"/"키워드" 탭 — 선택된 쪽만 밑줄(진짜 탭바처럼 같은 화면 안에서 전환).
    var topBarSection: some View {
        HStack(spacing: 0) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.wssBlack)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 44, height: 44)

            tabItem("정보", tab: .info, hasActiveFilter: hasActiveInfoFilter)

            Spacer().frame(width: 16)

            tabItem("키워드", tab: .keyword, hasActiveFilter: hasActiveKeywordFilter)

            Spacer()
        }
        .padding(.leading, 6)
    }

    /// 탭 라벨 + 밑줄(선택된 쪽으로 슬라이드) + 오른쪽 위 작은 점(그 탭에 선택된 항목이 있음,
    /// `LibraryFilterSheet` 탭 점과 동일 패턴). 밑줄 슬라이드는 `SosoFeedView.tabButton`과 동일하게
    /// `matchedGeometryEffect` — 같은 `id`를 가진 밑줄이 선택된 탭 쪽에만 조건부로 존재해, 선택이 바뀔 때
    /// 사라지는 대신 새 위치로 미끄러진다(opacity만 토글하면 슬라이드 없이 제자리에서 사라졌다 나타난다).
    private func tabItem(_ title: String, tab: Tab, hasActiveFilter: Bool) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            HStack(alignment: .top, spacing: 3) {
                VStack(spacing: 8) {
                    Text(title)
                        .applyWSSFont(.title1, color: isSelected ? .wssPrimary100 : .wssGray200)

                    ZStack {
                        if isSelected {
                            Rectangle()
                                .fill(Color.wssPrimary100)
                                .frame(height: 2)
                                .matchedGeometryEffect(id: "DETAIL_SEARCH_FILTER_TAB_INDICATOR", in: tabAnimation)
                        } else {
                            Color.clear
                                .frame(height: 2)
                        }
                    }
                }
                .fixedSize()

                Circle()
                    .fill(Color.wssPrimary100)
                    .frame(width: 4, height: 4)
                    .opacity(hasActiveFilter ? 1 : 0)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .buttonStyle(.plain)
    }

    var genreSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("장르")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            Spacer().frame(height: 16)

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
    }

    /// 플랫폼 — 라벨 옆 아이콘을 탭하면 베타 기능 안내 툴팁이 뜬다(다시 탭하면 닫힘). 안내 문구와 달리
    /// 실제로 서버에 반영되는 필터다(#185, 사용자 확정).
    var platformSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                sectionTitle("플랫폼")
                platformBetaInfoButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            Spacer().frame(height: 12)

            WSSFlowLayout(horizontalSpacing: 6, verticalSpacing: 14) {
                ForEach(Self.platformOrder, id: \.self) { platform in
                    CapsuleSelectableKeywordChip(
                        keyword: platform.displayName,
                        isSelected: viewModel.state.filter.platforms.contains(platform)
                    ) {
                        viewModel.handle(.togglePlatform(platform))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    var publicationStatusSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("연재상태")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            Spacer().frame(height: 12)

            HStack(spacing: 0) {
                ForEach(Array(Self.publicationStatusOrder.enumerated()), id: \.element) { index, status in
                    if index > 0 {
                        Spacer().frame(width: 11)
                    }
                    RectangleSelectableKeywordChip(
                        keyword: status.searchDisplayName,
                        isSelected: viewModel.state.filter.publicationStatus == status
                    ) {
                        viewModel.handle(.togglePublicationStatus(status))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
    }

    var ratingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                sectionTitle("별점")
                Spacer()
                Text(ratingRangeText)
                    .applyWSSFont(.body2, color: .wssPrimary100)
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 12)

            HStack(spacing: 0) {
                ratingValueBox(viewModel.state.ratingMin)
                Spacer().frame(width: 17)
                WSSRangeSlider(
                    min: viewModel.state.ratingMin,
                    max: viewModel.state.ratingMax,
                    isDisabled: false
                ) { min, max in
                    viewModel.handle(.changeRatingRange(min: min, max: max))
                }
                Spacer().frame(width: 17)
                ratingValueBox(viewModel.state.ratingMax)
            }
            .padding(.horizontal, 20)
        }
    }

    /// 초기화(화면 필터 전체 리셋) + 작품 찾기(확정 → `onSearch` 콜백 → pop).
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
                        .strokeBorder(Color.wssGray80, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Spacer().frame(width: 10)

            WSSCTAButton(title: "작품 찾기") {
                onSearch(viewModel.state.filter)
                dismiss()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Presentation

private extension DetailSearchFilterView {

    /// "정보" 탭에 선택된 항목이 하나라도 있는지 — 장르·플랫폼·연재상태·별점 4종만 본다(이 탭이 다루는 필드).
    /// `ratingThreshold`는 이 화면이 건드리지 않는 값이라 포함하지 않는다.
    var hasActiveInfoFilter: Bool {
        let filter = viewModel.state.filter
        return !filter.genres.isEmpty
            || !filter.platforms.isEmpty
            || filter.publicationStatus != nil
            || filter.ratingRange != nil
    }

    /// "키워드" 탭에 선택된 항목이 있는지 — 탭 콘텐츠는 아직 비어있지만(#185) 점 표시는 도메인 값
    /// (`SearchFilter.keywords`) 기준으로 미리 만들어둔다. 나중에 키워드 탭을 채우면 그대로 맞아떨어진다.
    var hasActiveKeywordFilter: Bool {
        !viewModel.state.filter.keywords.isEmpty
    }

    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .applyWSSFont(.title2, color: .wssBlack)
    }

    func ratingValueBox(_ value: Float) -> some View {
        Text(String(format: "%.1f", value))
            .applyWSSFont(.body2, color: .wssPrimary100)
            .frame(width: 50, height: 38)
            .background(Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    var ratingRangeText: String {
        String(format: "%.1f ~ %.1f", viewModel.state.ratingMin, viewModel.state.ratingMax)
    }

    /// 안내 아이콘 — 탭하면 베타 기능 툴팁이 뜨고(다시 탭하면 닫힘), 상시 노출 배지가 아니다(사용자 확정).
    var platformBetaInfoButton: some View {
        Button {
            isPlatformBetaTooltipPresented.toggle()
        } label: {
            WSSImage.icToolTip.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 13, height: 13)
        }
        .contentShape(Rectangle())
        .overlay(alignment: .leading) {
            if isPlatformBetaTooltipPresented {
                platformBetaTooltip
                    .fixedSize()
                    .offset(x: 18)
            }
        }
    }

    /// "아직 개발 중인 베타 기능이에요." 툴팁 본문. Figma는 말풍선 포인터가 달린 모양(`Union` 에셋)이지만
    /// 텍스트 길이에 따라 유동적이어야 해서 포인터 없는 캡슐로 단순화했다 — 색·텍스트는 그대로.
    var platformBetaTooltip: some View {
        Text("아직 개발 중인 베타 기능이에요.")
            .applyWSSFont(.body5, color: .wssPrimary100)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.wssPrimary50)
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DetailSearchFilterView(
            filter: SearchFilter(genres: [.romance, .drama], platforms: [.kakaoPage, .ridibooks]),
            onSearch: { print("검색 필터: \($0)") }
        )
    }
}
