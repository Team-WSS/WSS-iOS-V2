//
//  DetailSearchResultView.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import SearchDomain
import DesignSystem
import WSSComponent

/// `.navigationDestination(item:)`용 얇은 래퍼 — `NormalSearchView`의 `DetailSearchNavigation`과 동일 패턴
/// (탭마다 새 값이라 UUID로 값 동일성을 대신한다). **`isPresented:` + 별도 State 조합은 쓰지 않는다** —
/// 그 조합은 SwiftUI가 목적지 뷰의 `@State`를 미리 평가해 굳혀 재진입 시 갱신된 필터가 반영되지 않을 수
/// 있다(Feature CLAUDE.md "표시 상태 소유 구분" 참고, 서재 필터 시트에서 실제 발생했던 함정과 같은 종류).
private struct FilterEditorNavigation: Hashable {
    let id = UUID()
    let filter: SearchFilter

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct DetailSearchResultView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var viewModel: DetailSearchResultViewModel
    /// 필터 요약 pill 탭 → 상세탐색 필터 화면(정보 탭) push. 그 화면의 "작품 찾기"가 `updateFilter`로 돌아온다.
    @State private var filterEditorNavigation: FilterEditorNavigation?

    /// `DetailSearchFilterView`의 "키워드" 탭까지 그대로 흘려보낸다(`KeywordTabContentBuilder` 문서 참고).
    private let keywordTabContent: KeywordTabContentBuilder

    init(viewModel: DetailSearchResultViewModel, keywordTabContent: @escaping KeywordTabContentBuilder) {
        self._viewModel = State(initialValue: viewModel)
        self.keywordTabContent = keywordTabContent
    }

    var body: some View {
        content
            .navigationBarBackButtonHidden()
            .background(WSSColor.wssWhite.swiftUIColor)
            .onAppear { viewModel.handle(.load) }
            .navigationDestination(item: $filterEditorNavigation) { navigation in
                DetailSearchFilterView(filter: navigation.filter, keywordTabContent: keywordTabContent) { newFilter in
                    viewModel.handle(.updateFilter(newFilter))
                }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            topBarSection
                .padding(.leading, 6)
                .padding(.trailing, 20)

            Spacer().frame(height: 11)

            resultContent
        }
    }

    // MARK: - Sections

    private var topBarSection: some View {
        HStack(spacing: 0) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 44, height: 44)

            HStack(spacing: 0) {
                Text(filterSummaryText)
                    .applyWSSFont(.body4)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)

                Spacer()

                WSSImage.icController.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 18, height: 20)

            }
            .padding(.leading, 16)
            .padding(.trailing, 21)
            .frame(height: 42)
            .background(WSSColor.wssGray50.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .onTapGesture {
                filterEditorNavigation = FilterEditorNavigation(filter: viewModel.state.filter)
            }
        }
    }

    private var infoSection: some View {
        HStack(spacing: 0) {
            Text("작품")
                .applyWSSFont(.title1)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)

            Spacer().frame(width: 5)

            Text("\(viewModel.state.totalNovelCount)")
                .applyWSSFont(.body4)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)

            Spacer()

            Button {
                if let url = AppURL.inquiryAddNovel { openURL(url) }
            } label: {
                Text("찾는 작품이 없다면?")
                    .applyWSSFont(.body4)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    .underline()
            }
        }
    }

    @ViewBuilder
    private var resultContent: some View {
        if viewModel.state.isLoading {
            LoadingView()
        } else if viewModel.state.hasLoadError {
            NetworkErrorView(action: { viewModel.handle(.load) })
        } else if viewModel.state.novels.isEmpty {
            Spacer()
            VStack(spacing: 10) {
                WSSImage.imgEmpty.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 39)
                
                Text("해당하는 작품이 없어요\n검색의 범위를 더 넓혀보세요")
                    .applyWSSFont(.body1)
                    .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        } else {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    infoSection

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 9),
                            GridItem(.flexible())
                        ],
                        spacing: 18
                    ) {
                        ForEach(viewModel.state.novels, id: \.id) { novel in
                            DetailSearchResultItemRow(novel: novel)
                                // 무한스크롤 — 마지막 행이 화면에 보이는 순간 다음 페이지 요청(중복 방지는 VM 가드가 담당).
                                .onAppear {
                                    if novel.id == viewModel.state.novels.last?.id {
                                        viewModel.handle(.loadMore)
                                    }
                                }
                        }
                    }

                    if viewModel.state.isLoadingMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
            }
            .contentMargins(.bottom, 20, for: .scrollContent)
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

// MARK: - Presentation

private extension DetailSearchResultView {
    /// 적용된 필터 카테고리를 "장르, 키워드 적용"처럼 나열한다. 현재는 장르 탭/키워드 탭이 각각 한 카테고리만 채워 넣지만,
    /// 이후 상세 필터 화면에서 여러 카테고리가 동시에 채워져도 그대로 동작하도록 전 카테고리를 훑는다.
    var filterSummaryText: String {
        let filter = viewModel.state.filter
        var appliedCategories: [String] = []
        if !filter.genres.isEmpty { appliedCategories.append("장르") }
        if !filter.platforms.isEmpty { appliedCategories.append("플랫폼") }
        if !filter.keywords.isEmpty { appliedCategories.append("키워드") }
        if filter.publicationStatus != nil { appliedCategories.append("연재상태") }
        if filter.ratingThreshold != nil || filter.ratingRange != nil { appliedCategories.append("별점") }

        guard !appliedCategories.isEmpty else { return "전체 작품" }
        return appliedCategories.joined(separator: ", ") + " 적용"
    }
}

#Preview {
    NavigationStack {
        DetailSearchResultView(
            viewModel: DetailSearchResultViewModel(
                filter: SearchFilter(genres: [.romance], keywords: [Keyword(id: KeywordID(1), name: "환생")]),
                searchNovelUseCase: PreviewSearchNovelUseCase()
            ),
            keywordTabContent: { _, _ in AnyView(Text("키워드 탭 콘텐츠 자리(프리뷰 스텁)")) }
        )
    }
}

private struct PreviewSearchNovelUseCase: SearchNovelUseCase {
    func searchByText(_ query: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        (Paginated(items: [], hasNext: false), 0)
    }

    func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        let novels = (1...5).map { index in
            Novel(id: NovelID(index),
                  thumbnailImage: URL(string: "https://i.pinimg.com/1200x/40/cb/df/40cbdfcce149156643cc6eae5e0dec6f.jpg"),
                  title: "미리보기 작품 \(index)",
                  authors: ["프리뷰 작가"],
                  genres: [],
                  interestCount: 8,
                  rating: 4.9,
                  ratingCount: 2,
                  isInterested: false)
        }
        return (Paginated(items: novels, hasNext: false), novels.count)
    }
}
