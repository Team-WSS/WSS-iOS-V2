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

    @State private var viewModel: NormalSearchViewModel

    @State private var searchText: String = ""
    @FocusState var isFocused: Bool

    init(viewModel: NormalSearchViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            topbarSection
                .padding(.leading, 6)
                .padding(.trailing, 20)

            Spacer().frame(height: 20)

            if !viewModel.state.recentSearchWords.isEmpty {
                recentSearchKeywordSection

                Spacer().frame(height: 32)
            }

            genreSearchSection

            Spacer().frame(height: 32)

            keywordSearchSection

            Spacer().frame(height: 32)

            sosoPickSection

            Spacer()
        }
        .onAppear {
            viewModel.handle(.loadSosoPick)
            viewModel.handle(.loadRecentSearchWords)
            viewModel.handle(.loadPopularKeywords)
        }
    }
    
    // MARK: - Top Bar

    private var topbarSection: some View {
        HStack(spacing: 0) {
            Button {
                // dismiss
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 44, height: 44)

            Spacer().frame(width: 6)

            WSSSearchBar(text: $searchText,
                         placeholder: "작품 제목, 작가를 검색하세요",
                         isFocused: $isFocused,
                         onSearch: { })
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
                                searchText = word.title
                                // TODO: - 검색 실행(WSSSearchBar의 onSearch와 동일 로직 필요)
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
                    // TODO: - 탐색 정보탭으로 이동
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
            // TODO: - genre 검색 이동
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
                    // TODO: - 탐색 키워드탭으로 이동
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
                            searchText = keyword.name
                            // TODO: - 검색 실행(WSSSearchBar의 onSearch와 동일 로직 필요)
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
                        sosoPickItem(imageURL: pick.novelThumbnailimage,
                                     title: pick.novelTitle)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            print("\(pick.novelID)번 작품 상세로 이동")
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 20)
        }
    }
    
    private func sosoPickItem(imageURL: URL?, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                case .failure(_):
                    WSSImage.imgEmpty.swiftUIImage.resizable()
                default:
                    ProgressView()
                }
            }
            .scaledToFill()
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

private struct PreviewLoadPopularKeywordsUseCase: LoadPopularKeywordsUseCase {
    func execute() async throws(RepositoryError) -> PopularKeywords {
        PopularKeywords(keywords: [
            Keyword(id: KeywordID(1), name: "이세계"),
            Keyword(id: KeywordID(2), name: "회귀"),
            Keyword(id: KeywordID(3), name: "환생")
        ])
    }
}
