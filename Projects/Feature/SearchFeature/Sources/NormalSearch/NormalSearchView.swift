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

import DesignSystem
import WSSComponent

public struct NormalSearchView: View {
    
    @State private var viewModel: NormalSearchViewModel
    
    @State private var searchText: String = ""
    @FocusState var isFocused: Bool
    
    public init(viewModel: NormalSearchViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            TopbarSection
                .padding(.leading, 6)
                .padding(.trailing, 20)
            
            Spacer().frame(height: 20)
            
            recentSearchKeywordSection
            
            Spacer().frame(height: 32)
            
            genreSearchSection
            
            Spacer().frame(height: 32)
            
            keywordSearchSection
            
            Spacer().frame(height: 32)
            
            sosoPickSection

            Spacer()
        }
        .onAppear {
            viewModel.handle(.loadSosoPick)
        }
    }
    
    // MARK: - Top Bar
    
    private var TopbarSection: some View {
        HStack(spacing: 6) {
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
            
            WSSSearchBar(text: $searchText,
                         placeholder: "작품 제목, 작가를 검색하세요",
                         isFocused: $isFocused,
                         onSearch: { })
        }
    }
    
    // MARK: - 최근 검색어
    
    private var recentSearchKeywordSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text("최근 검색어")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                
                Spacer()
                
                Button {
                    // TODO: - 전체 삭제
                } label: {
                    Text("전체 삭제")
                        .applyWSSFont(.body4)
                        .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal,
                       showsIndicators: false) {
                HStack(spacing: 6) {
                    WhiteRemovableKeywordChip(keyword: "안녕",
                                              action: {})
                    WhiteRemovableKeywordChip(keyword: "안녕",
                                              action: {})
                    WhiteRemovableKeywordChip(keyword: "안녕",
                                              action: {})
                    WhiteRemovableKeywordChip(keyword: "안녕",
                                              action: {})
                    WhiteRemovableKeywordChip(keyword: "안녕",
                                              action: {})
                    WhiteRemovableKeywordChip(keyword: "안녕",
                                              action: {})
                    WhiteRemovableKeywordChip(keyword: "안녕",
                                              action: {})
                }
            }
            .contentMargins(.horizontal, 20)
        }
    }
    
    // MARK: - 장르별 검색
    
    private var genreSearchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 3) {
                Text("장르별 검색")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 3) {
                Text("키워드 검색")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                
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
            
            WSSFlowLayout(horizontalSpacing: 6, verticalSpacing: 8) {
                ForEach(0..<10, id: \.self) { _ in
                    CapsuleSelectableKeywordChip(keyword: "안녕",
                                                 isSelected: false,
                                                 action: { })
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 소소픽
    
    private var sosoPickSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Text("소소")
                        .applyWSSFont(.title2)
                        .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    
                    WSSImage.icTextPick.swiftUIImage
                }
                
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
                loadSosoPickUseCase: PreviewLoadSosoPickUseCase()
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
