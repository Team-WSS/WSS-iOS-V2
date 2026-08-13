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
/// dismiss로 되돌아간다). 하단 초기화/작품 찾기 CTA는 **버튼 자체는 두 탭 공용**이라 탭 전환과 무관하게 항상
/// 보이지만, "초기화"가 지우는 대상은 **현재 보고 있는 탭의 데이터만**이다(사용자 확정 — 탭별 독립 초기화).
///
/// "키워드" 탭 콘텐츠는 `KeywordFeature`의 키워드 선택 화면을 재사용하지만, `SearchFeature`는 `KeywordFeature`를
/// **모른다**(Feature 간 직접 의존 금지) — 그 콘텐츠는 `keywordTabContent`(`KeywordTabContentBuilder`)로
/// App/Demo가 조립해 값으로 건네받는다. 자세한 계약은 `Navigation/KeywordTabContentBuilder.swift` 참고.
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
    /// "초기화"를 누르면 새 값으로 바꿔 키워드 탭 콘텐츠에 `.id()`로 건다 — `keywordTabContent`가 매번 새
    /// `initialKeywords`로 호출돼도, 그 콘텐츠 내부 `@State`(선택 목록)는 뷰 정체성이 같으면 최초 1회만
    /// 시딩되고 이후 갱신되지 않는 SwiftUI 함정이 있다(Feature CLAUDE.md "표시 상태 소유 구분" 참고) —
    /// 정체성 자체를 바꿔 강제로 다시 시딩한다.
    @State private var keywordContentResetToken = UUID()

    private let keywordTabContent: KeywordTabContentBuilder
    private let onSearch: (SearchFilter) -> Void

    /// Figma 실측 — `WSSComponent.NovelGenre.myFeedFilter`와 노출 순서가 같다(`SearchDomain/CLAUDE.md` 참고).
    private static let genreOrder = NovelGenre.myFeedFilter
    private static let platformOrder = NovelPlatform.allCases
    private static let publicationStatusOrder: [NovelPublicationStatus] = [.onGoing, .completed]

    init(
        filter: SearchFilter,
        keywordTabContent: @escaping KeywordTabContentBuilder,
        onSearch: @escaping (SearchFilter) -> Void
    ) {
        self._viewModel = State(initialValue: DetailSearchFilterViewModel(filter: filter))
        self.keywordTabContent = keywordTabContent
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
            // 콘텐츠 자체가 자기 스크롤을 갖고 있어(KeywordFeature 화면) 여기서 또 ScrollView로 감싸지 않는다.
            keywordTabContent(viewModel.state.filter.keywords) { newKeywords in
                viewModel.handle(.setKeywords(newKeywords))
            }
            .id(keywordContentResetToken)
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
            
            Spacer().frame(width: 18)

            tabItem("정보", tab: .info, hasActiveFilter: hasActiveInfoFilter)

            Spacer().frame(width: 22)

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

            Spacer().frame(height: 13)

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

            Spacer().frame(height: 16)

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
            .padding(.horizontal, 16)

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

    /// 초기화(**보고 있는 탭의 데이터만** 각자 리셋 — 사용자 확정) + 작품 찾기(확정 → `onSearch` 콜백 → pop).
    var ctaSection: some View {
        HStack(spacing: 0) {
            Button {
                switch selectedTab {
                case .info:
                    viewModel.handle(.clearInfoFilters)
                case .keyword:
                    viewModel.handle(.clearKeywords)
                    // 키워드 탭 콘텐츠는 외부(KeywordFeature) 상태라 filter.keywords를 지운 것만으론 화면에
                    // 반영 안 된다 — 정체성을 바꿔 강제로 다시 시딩한다(위 keywordContentResetToken 주석 참고).
                    keywordContentResetToken = UUID()
                }
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

    /// "키워드" 탭에 선택된 항목이 있는지 — `keywordTabContent`의 `onSelectionChanged`로 갱신되는
    /// `SearchFilter.keywords` 기준으로 판단한다.
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
    /// 트리거 아이콘 쪽(`.leading`)을 기준점 삼아 그 자리에서 살짝 커지며 나타나고 줄어들며 사라지도록
    /// `scale`+`opacity`를 함께 건다 — 툴팁 없이 `if`만 쓰면 트랜지션이 없어 즉시 나타났다 사라진다.
    var platformBetaInfoButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                isPlatformBetaTooltipPresented.toggle()
            }
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
                    .transition(.scale(scale: 0.85, anchor: .leading).combined(with: .opacity))
            }
        }
    }

    /// "아직 개발 중인 베타 기능이에요." 툴팁 본문 — 텍스트가 항상 고정 문구라 화면 크기와 무관하게 폭이
    /// 일정하므로, 텍스트 길이에 맞춰 늘어나는 커스텀 Shape 대신 Figma 원본 말풍선 에셋
    /// (`WSSImage.icPlatformTooltip`, 왼쪽 포인터 포함 180×28 고정)을 그대로 쓴다.
    var platformBetaTooltip: some View {
        Text("아직 개발 중인 베타 기능이에요.")
            .applyWSSFont(.body5, color: .wssPrimary100)
            .frame(width: 180, height: 28)
            .background {
                WSSImage.icPlatformTooltip.swiftUIImage
                    .resizable()
            }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DetailSearchFilterView(
            filter: SearchFilter(genres: [.romance, .drama], platforms: [.kakaoPage, .ridibooks]),
            keywordTabContent: { initialKeywords, _ in
                AnyView(
                    VStack {
                        Text("키워드 탭 콘텐츠 자리(프리뷰 스텁)")
                        Text("초기 선택: \(initialKeywords.map(\.name).joined(separator: ", "))")
                    }
                )
            },
            onSearch: { print("검색 필터: \($0)") }
        )
    }
}
