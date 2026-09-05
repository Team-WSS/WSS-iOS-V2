//
//  NormalSearchView.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import RecommendationDomain
import SearchDomain
import DesignSystem
import WSSComponent

struct NormalSearchView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: NormalSearchViewModel

    @FocusState var isFocused: Bool

    /// 진입 시 검색창 자동 포커스를 최초 1회만 걸기 위한 가드(작품 상세 등에서 복귀 시 재발화 방지, #222 V1 parity).
    @State private var didAutoFocus = false

    /// 검색어 `TextField`는 VM 상태에 직접 물리지 않고 이 로컬 버퍼를 거친다 — 30자 clamp를 `Binding.set`에서
    /// 바로 하면 네이티브 필드가 초과분을 화면에 들고 있는 함정이 있어서다(글자수 제한 TextField 2단계 패턴, #222).
    @State private var searchDraft: String

    /// 검색 결과 작품 셀 탭 → 작품 상세 진입 콜백. 실제 화면 전환은 호출자(App 조정 계층)가 수행한다.
    private let onNovelSelected: (NovelID) -> Void
    /// 장르 탭·인기 키워드 칩 탭 → 상세탐색 결과(`DetailSearchResultView`) 진입 콜백. 실제 화면 전환은
    /// 호출자(App 조정 계층)가 수행한다 — App이 소유한 `NavigationPath`에 직접 push해야 그 안에서 다시
    /// `onNovelSelected`로 작품 상세를 열 때 화면이 제대로 쌓인다(아래 주의사항 참고, #196).
    private let onDetailSearchRequested: (SearchFilter) -> Void
    /// 장르·키워드 섹션 "더보기" 헤더 → 상세탐색 **필터 화면** 진입 콜백(#236, V1 parity).
    /// 장르 더보기는 정보 탭(`.info`), 키워드 더보기는 키워드 탭(`.keyword`)으로 연다.
    private let onDetailSearchFilterRequested: (DetailSearchFilterTab) -> Void

    init(
        viewModel: NormalSearchViewModel,
        onNovelSelected: @escaping (NovelID) -> Void = { _ in },
        onDetailSearchRequested: @escaping (SearchFilter) -> Void = { _ in },
        onDetailSearchFilterRequested: @escaping (DetailSearchFilterTab) -> Void = { _ in }
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onNovelSelected = onNovelSelected
        self.onDetailSearchRequested = onDetailSearchRequested
        self.onDetailSearchFilterRequested = onDetailSearchFilterRequested
        // initialQuery로 진입 시 VM이 init에서 이미 searchText를 채워두므로 로컬 버퍼도 그 값으로 시작한다.
        self._searchDraft = State(initialValue: viewModel.state.searchText)
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                topbarSection
                    .padding(.leading, 6)
                    .padding(.trailing, 20)
                
                Spacer().frame(height: 11)
                
                if viewModel.state.isSearchExecuted {
                    NormalSearchResultView(
                        novels: viewModel.state.searchResultNovels,
                        resultCount: viewModel.state.searchResultCount,
                        isLoading: viewModel.state.isSearchingResult,
                        loadError: viewModel.state.hasSearchResultError,
                        isLoadingMore: viewModel.state.isLoadingMoreSearchResults,
                        onLoadMore: { viewModel.handle(.loadMoreSearchResults) },
                        onRetry: { viewModel.handle(.executeSearch(viewModel.state.searchText)) },
                        onNovelSelected: onNovelSelected
                    )
                } else if isFocused, !viewModel.state.searchText.isEmpty {
                    NormalSearchAutoCompletionView(
                        searchText: viewModel.state.searchText,
                        words: viewModel.state.autoCompletionWords,
                        isLoading: viewModel.state.isLoadingAutoCompletion,
                        onSelect: { word in
                            isFocused = false
                            viewModel.handle(.executeSearch(word.word))
                        },
                        onDismissKeyboard: { isFocused = false }
                    )
                } else {
                    Spacer().frame(height: 8)
                    
                    if !viewModel.state.recentSearchWords.isEmpty {
                        recentSearchKeywordSection
                        
                        Spacer().frame(height: 32)
                    }
                    
                    genreSearchSection
                    
                    Spacer().frame(height: 32)
                    
                    keywordSearchSection
                    
                    Spacer().frame(height: 32)
                    
                    sosoPickSection
                }
                
                Spacer()
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .contentShape(Rectangle())
            .onTapGesture { isFocused = false }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(WSSColor.wssWhite.swiftUIColor)
        .ignoresSafeArea(.container, edges: .bottom)
        // 커스텀 상단바(뒤로가기+검색바)를 자체적으로 그리므로 시스템 네비바를 숨기고(iOS 26 빈 글래스 바 제거),
        // 네비바 숨김이 함께 꺼버리는 스와이프 뒤로가기를 되살린다.
        .wssCustomNavigationBar()
        .onAppear {
            viewModel.handle(.loadSosoPick)
            viewModel.handle(.loadRecentSearchWords)
            viewModel.handle(.loadPopularKeywords)
            // V1 parity: 진입 시 검색창에 자동 포커스(키보드 바로 뜸). 단 initialQuery로 이미 검색이
            // 실행된 경우(작가명 탭 등)엔 결과 화면을 보여줘야 하므로 포커스하지 않는다. 최초 1회만,
            // push 애니메이션이 끝난 뒤(포커스가 씹히지 않게) 건다.
            if !didAutoFocus, !viewModel.state.isSearchExecuted {
                didAutoFocus = true
                // @MainActor 명시 필수 — 평범한 Task {}는 메인 액터를 상속하지 않아 @FocusState(main-actor)
                // 설정이 무시돼 포커스가 안 걸린다(시뮬레이터 실측).
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(350))
                    isFocused = true
                }
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topbarSection: some View {
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
            
            Spacer().frame(width: 6)
            
            WSSSearchBar(text: $searchDraft,
                         placeholder: "작품 제목, 작가를 검색하세요",
                         isFocused: $isFocused,
                         onSearch: {
                isFocused = false
                viewModel.handle(.executeSearch(viewModel.state.searchText))
            })
            // 로컬 버퍼 → 30자 clamp → (초과면 로컬 재대입해 네이티브 필드 되돌림 / 아니면 VM 전달)의 2단계.
            .onChange(of: searchDraft) { _, newValue in
                let clamped = String(newValue.prefix(NormalSearchViewModel.maxSearchTextCount))
                if clamped != newValue {
                    searchDraft = clamped
                    return
                }
                viewModel.handle(.updateSearchText(clamped))
            }
            // 검색 실행 시 trim·최근 검색어/제안어 탭처럼 VM이 검색어를 바꾸면 로컬 버퍼를 맞춘다.
            .onChange(of: viewModel.state.searchText) { _, newValue in
                guard searchDraft != newValue else { return }
                searchDraft = newValue
            }
        }
    }
    
    // MARK: - 최근 검색어
    
    private var recentSearchKeywordSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("최근 검색어")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                
                Spacer()
                
                Button {
                    viewModel.handle(.clearRecentSearchWords)
                } label: {
                    Text("전체 삭제")
                        .applyWSSFont(.body4)
                        .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 12)
            
            ScrollView(.horizontal,
                       showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.state.recentSearchWords, id: \.id) { word in
                        WhiteRemovableKeywordChip(
                            keyword: word.title,
                            onSelect: {
                                isFocused = false
                                viewModel.handle(.executeSearch(word.title))
                            },
                            onDelete: { viewModel.handle(.removeRecentSearchWord(word)) }
                        )
                    }
                }
            }
                       .scrollBounceBehavior(.basedOnSize,
                                             axes: .horizontal)
                       .contentMargins(.horizontal, 20)
        }
    }
    
    // MARK: - 장르별 검색
    
    private var genreSearchSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("장르별 검색")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                
                Spacer().frame(width: 3)
                
                Button {
                    onDetailSearchFilterRequested(.info)
                } label: {
                    WSSImage.icNavigateRight.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 12)
            
            ScrollView(.horizontal,
                       showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(NovelGenre.searchGenre, id: \.displayName) { genre in
                        genreItem(genre: genre)
                    }
                }
            }
                       .contentMargins(.horizontal, 20)
        }
    }
    
    private func genreItem(genre: NovelGenre) -> some View {
        Button {
            onDetailSearchRequested(SearchFilter(genres: [genre]))
        } label: {
            VStack(spacing: 9) {
                genre.iconImage
                    .resizable()
                    .frame(width: 32, height: 32)
                
                Text(genre.displayName)
                    .applyWSSFont(.body3)
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                    .fixedSize()
            }
        }
        .frame(width: 44)
    }
    
    // MARK: - 키워드 검색
    
    private var keywordSearchSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("키워드 검색")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                
                Spacer().frame(width: 3)
                
                Button {
                    onDetailSearchFilterRequested(.keyword)
                } label: {
                    WSSImage.icNavigateRight.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                        .frame(width: 16, height: 16)
                }
            }
            
            Spacer().frame(height: 12)
            
            WSSFlowLayout(horizontalSpacing: 6, verticalSpacing: 8) {
                ForEach(viewModel.state.popularKeywords, id: \.id) { keyword in
                    CapsuleSelectableKeywordChip(
                        keyword: keyword.name,
                        isSelected: false,
                        action: {
                            onDetailSearchRequested(SearchFilter(keywords: [keyword]))
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 소소픽
    
    private var sosoPickSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("소소")
                        .applyWSSFont(.title2)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    
                    Spacer().frame(width: 2)
                    
                    WSSImage.icTextPick.swiftUIImage
                }
                
                Spacer().frame(height: 2)
                
                Text("다른 독자들이 최근에 찾아본 웹소설이에요")
                    .applyWSSFont(.body4)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
            }
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 12)
            
            ScrollView(.horizontal,
                       showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.state.sosoPickNovels, id: \.novelID) { pick in
                        Button {
                            onNovelSelected(pick.novelID)
                        } label: {
                            sosoPickItem(imageURL: pick.novelThumbnailimage,
                                         title: pick.novelTitle)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
                       .contentMargins(.horizontal, 20)
        }
    }
    
    private func sosoPickItem(imageURL: URL?, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            WSSNovelCoverImage(url: imageURL, placeholderStyle: .grid)
                .frame(width: 121, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .applyWSSFont(.body4)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 121, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        NormalSearchView(
            viewModel: NormalSearchViewModel(
                loadSosoPickUseCase: PreviewLoadSosoPickUseCase(),
                loadRecentSearchWordsUseCase: PreviewLoadRecentSearchWordsUseCase(),
                removeRecentSearchWordUseCase: PreviewRemoveRecentSearchWordUseCase(),
                clearRecentSearchWordsUseCase: PreviewClearRecentSearchWordsUseCase(),
                searchAutoCompletionWordsUseCase: PreviewSearchAutoCompletionWordsUseCase(),
                searchNovelUseCase: PreviewSearchNovelUseCase(),
                loadPopularKeywordsUseCase: PreviewLoadPopularKeywordsUseCase()
            )
        )
    }
}

private struct PreviewLoadSosoPickUseCase: LoadSosoPickUseCase {
    func execute() async throws(RepositoryError) -> [SosoPick] {
        [
            SosoPick(
                novelID: NovelID(1),
                novelTitle: "적국의 황자를 길들여버렸다",
                novelThumbnailimage: URL(string: "https://i.pinimg.com/1200x/40/cb/df/40cbdfcce149156643cc6eae5e0dec6f.jpg")
            )
        ]
    }
}

private struct PreviewLoadRecentSearchWordsUseCase: LoadRecentSearchWordsUseCase {
    func execute() async throws(RepositoryError) -> [RecentSearchWord] {
        [
            RecentSearchWord(id: SearchWordID(1), title: "환생물"),
            RecentSearchWord(id: SearchWordID(2), title: "회귀물")
        ]
    }
}

private struct PreviewRemoveRecentSearchWordUseCase: RemoveRecentSearchWordUseCase {
    func execute(word: RecentSearchWord) async throws(RepositoryError) {}
}

private struct PreviewClearRecentSearchWordsUseCase: ClearRecentSearchWordsUseCase {
    func execute() async throws(RepositoryError) {}
}

private struct PreviewSearchAutoCompletionWordsUseCase: SearchAutoCompletionWordsUseCase {
    func execute(searchText: String) async throws(RepositoryError) -> [SearchAutoCompletionWord] {
        [
            SearchAutoCompletionWord(word: "\(searchText) 로맨스"),
            SearchAutoCompletionWord(word: "\(searchText) 판타지")
        ]
    }
}

private struct PreviewSearchNovelUseCase: SearchNovelUseCase {
    func searchByText(_ query: String, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        let novels = [
            Novel(id: NovelID(1),
                  thumbnailImage: URL(string: "https://i.pinimg.com/1200x/40/cb/df/40cbdfcce149156643cc6eae5e0dec6f.jpg"),
                  title: "\(query) 미리보기 작품",
                  authors: ["프리뷰 작가"],
                  genres: [],
                  interestCount: 8,
                  rating: 4.9,
                  ratingCount: 2,
                  isInterested: false)
        ]
        return (Paginated(items: novels, hasNext: false), novels.count)
    }
    
    func searchByFilter(_ filter: SearchFilter, page: Int) async throws(RepositoryError) -> (Paginated<Novel>, Int) {
        (Paginated(items: [], hasNext: false), 0)
    }
}

private struct PreviewLoadPopularKeywordsUseCase: LoadPopularKeywordsUseCase {
    func execute() async throws(RepositoryError) -> PopularKeywords {
        PopularKeywords(keywords: [
            Keyword(id: KeywordID(1), name: "이세계"),
            Keyword(id: KeywordID(2), name: "회귀"),
            Keyword(id: KeywordID(3), name: "환생")
        ])
    }
}
