//
//  SearchKeywordView.swift
//  KeywordFeature
//
//  Created by Seoyeon Choi on 7/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import DesignSystem
import WSSComponent

struct SearchKeywordView: View {
    
    @State private var viewModel: SearchKeywordViewModel
    @State private var keywordText: String = ""
    @State private var expandedCategories: Set<KeywordCategory> = []
    @FocusState private var isSearchBarFocused: Bool

    // TODO: - 키워드 문의 URL enum이 아직 develop에 없는 별도 브랜치에 있음. 그 브랜치가 머지되면
    // WSSEmptyView(type: .keyword)의 action에서 openURL(...)로 연결할 것.
    @Environment(\.openURL) private var openURL

    init(viewModel: SearchKeywordViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    /// 실시간 검색이 아니라 제출(엔터·서치바 버튼) 시에만 갱신되는 `state.query` 기준으로 모드를 가른다.
    /// `keywordText` 기준이면 제출 전 타이핑 중에도 검색 결과 화면(빈 상태)이 먼저 보여 어색하다.
    private var isSearching: Bool { !viewModel.state.query.isEmpty }
    
    /// 서치바 포커스 중이거나 검색 결과를 보는 중엔 흰 배경(카테고리 브라우징 숨김)만 보여준다.
    private var showsWhiteBackground: Bool { isSearchBarFocused || isSearching }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                WSSSearchBar(text: $keywordText,
                             placeholder: "키워드를 검색하세요",
                             isFocused: $isSearchBarFocused,
                             onSearch: { viewModel.handle(.search(text: keywordText)) },
                             onCancel: {
                                 viewModel.handle(.search(text: ""))
                                 isSearchBarFocused = false
                             })
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                if !viewModel.state.selectedKeywords.isEmpty {
                    selectedKeywordTray
                        .padding(.bottom, 18)
                }
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(WSSColor.wssGray50.swiftUIColor)

            }
            .background(WSSColor.wssWhite.swiftUIColor)

            Group {
                if isSearching && viewModel.state.searchedKeywords.isEmpty {
                    // ScrollView 안에 두면 콘텐츠 크기만큼만 차지해 상단에 붙어버린다 — 화면을 다 차지하는
                    // 뷰로 빼서 화면 정중앙에 오도록 한다(스크롤도 불필요한 상태).
                    // action(문의 URL 연결)은 TODO — 위 openURL 프로퍼티 주석 참고.
                    WSSEmptyView(type: .keyword, action: { })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Spacer().frame(height: 8)

                        if showsWhiteBackground {
                            if isSearching {
                                searchResultSection
                            }
                        } else {
                            ForEach(KeywordCategory.allCases, id: \.self) { category in
                                keywordBlock(category: category)

                                Spacer().frame(height: 14)
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicators(.hidden)
                }
            }
            .background(showsWhiteBackground ? WSSColor.wssWhite.swiftUIColor : WSSColor.wssGray50.swiftUIColor)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomActionBar
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear { viewModel.handle(.load) }
        .showWSSToast(isPresented: toastBinding, type: .unknownError)
    }

    private var bottomActionBar: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.handle(.resetSelectedKeywords)
            } label: {
                HStack(spacing: 4) {
                    WSSImage.icReset.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 14, height: 14)

                    Text("초기화")
                        .applyWSSFont(.title2)
                }
                .padding(.horizontal, 18)
                .frame(height: 53)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .background(WSSColor.wssWhite.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(WSSColor.wssGray200.swiftUIColor, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            // TODO: - 키워드 선택 완료 로직 추가

            Button {

            } label: {
                Text("\(viewModel.state.selectedKeywords.count)개 선택")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssWhite.swiftUIColor)
                    .frame(height: 53)
                    .frame(maxWidth: .infinity)
                    .background(WSSColor.wssPrimary100.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(WSSColor.wssWhite.swiftUIColor)
    }
    
    private var selectedKeywordTray: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(viewModel.state.selectedKeywords) { keyword in
                        WhiteRemovableKeywordChip(
                            keyword: keyword.name,
                            onDelete: { viewModel.handle(.toggleKeyword(keyword)) }
                        )
                        .id(keyword.id)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .contentMargins(.horizontal, 20)
            .scrollIndicators(.hidden)
            .background(WSSColor.wssWhite.swiftUIColor)
            // 새로 선택한 키워드는 끝(오른쪽)에 추가된다 — 트레이가 넘쳐도 방금 고른 게 바로 보이도록 스크롤해 따라간다.
            // count로만 판단해 삭제(개수 감소) 시에는 스크롤하지 않는다.
            .onChange(of: viewModel.state.selectedKeywords.count) { oldCount, newCount in
                guard newCount > oldCount, let last = viewModel.state.selectedKeywords.last else { return }
                withAnimation {
                    proxy.scrollTo(last.id, anchor: .trailing)
                }
            }
        }
    }
    
    private var searchResultSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 28)

            Text("검색결과")
                .applyWSSFont(.title3)
                .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                .padding(.horizontal, 20)

            Spacer().frame(height: 20)

            WSSFlowLayout(
                horizontalSpacing: 6,
                verticalSpacing: 8
            ) {
                ForEach(viewModel.state.searchedKeywords) { keyword in
                    CapsuleSelectableKeywordChip(
                        keyword: keyword.name,
                        isSelected: viewModel.state.selectedKeywords.contains(keyword),
                        action: { viewModel.handle(.toggleKeyword(keyword)) }
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 28)
        }
        .frame(maxWidth: .infinity)
        .background(WSSColor.wssWhite.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }
    
    /// 키워드 칩 높이(35) + 줄 간격(8) + 키워드 칩 높이(35) + 여유(2) = 접힌 상태에서 2줄만 보이는 높이.
    private let collapsedKeywordAreaHeight: CGFloat = 80
    
    private func keywords(for category: KeywordCategory) -> [Keyword] {
        viewModel.state.groups.first(where: { $0.category == category })?.keywords ?? []
    }
    
    private func keywordBlock(category: KeywordCategory) -> some View {
        let isExpanded = expandedCategories.contains(category)
        
        return VStack(spacing: 0) {
            Spacer().frame(height: 20)
            
            HStack(spacing: 8) {
                category.iconImage
                
                Text(category.displayName)
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            WSSFlowLayout(
                horizontalSpacing: 6,
                verticalSpacing: 8
            ) {
                ForEach(keywords(for: category)) { keyword in
                    CapsuleSelectableKeywordChip(
                        keyword: keyword.name,
                        isSelected: viewModel.state.selectedKeywords.contains(keyword),
                        action: { viewModel.handle(.toggleKeyword(keyword)) }
                    )
                }
            }
            .frame(height: isExpanded ? nil : collapsedKeywordAreaHeight, alignment: .top)
            .clipped()
            .contentShape(Rectangle())
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            
            Spacer().frame(height: 14)
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
            
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                WSSImage.icChevronDown.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .frame(width: 44, height: 44)
        }
        .background(WSSColor.wssWhite.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }
}

// MARK: - Presentation

private extension SearchKeywordView {
    var toastBinding: Binding<Bool> {
        Binding(get: { viewModel.state.presentedError != nil },
                set: { if !$0 { viewModel.handle(.dismissError) } })
    }
}

#Preview {
    SearchKeywordView(viewModel: SearchKeywordViewModel(
        loadTotalKeywordsUseCase: PreviewLoadTotalKeywordsUseCase(),
        searchKeywordsUseCase: PreviewSearchKeywordsUseCase()
    ))
}

private struct PreviewLoadTotalKeywordsUseCase: LoadTotalKeywordsUseCase {
    func execute() async throws(RepositoryError) -> [KeywordGroup] {
        KeywordCategory.allCases.map { category in
            KeywordGroup(
                category: category,
                keywords: ["고양이", "강아지", "토끼", "여우", "코끼리"].enumerated().map {
                    Keyword(id: KeywordID($0.offset), name: $0.element)
                }
            )
        }
    }
}

private struct PreviewSearchKeywordsUseCase: SearchKeywordsUseCase {
    func execute(searchText: String) async throws(RepositoryError) -> [Keyword] {
        ["고양이", "강아지", "토끼", "여우", "코끼리"].enumerated()
            .map { Keyword(id: KeywordID($0.offset), name: $0.element) }
            .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}
