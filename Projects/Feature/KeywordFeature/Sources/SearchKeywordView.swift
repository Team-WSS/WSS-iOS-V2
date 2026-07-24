//
//  SearchKeywordView.swift
//  KeywordFeature
//
//  Created by Seoyeon Choi on 7/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

import BaseDomain

struct SearchKeywordView: View {

    @State private var viewModel: SearchKeywordViewModel
    @State private var keywordText: String = ""
    @State private var expandedCategories: Set<KeywordCategory> = []

    init(viewModel: SearchKeywordViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                WSSSearchBar(text: $keywordText,
                             placeholder: "키워드를 검색하세요",
                             onSearch: { })
                .padding(.horizontal, 20)
                .padding(.bottom, 25)
                .background(WSSColor.wssWhite.swiftUIColor)

                Spacer().frame(height: 8)

                ForEach(KeywordCategory.allCases, id: \.displayName) { category in
                    keywordBlock(category: category)

                    Spacer().frame(height: 14)
                }
                .padding(.horizontal, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .background(WSSColor.wssGray50.swiftUIColor)
        }
        .onAppear { viewModel.handle(.load) }
        .showWSSToast(isPresented: toastBinding, type: .unknownError)
    }

    /// 키워드 칩 높이(35) + 줄 간격(8) + 키워드 칩 높이(35) = 접힌 상태에서 정확히 2줄만 보이는 높이.
    private let collapsedKeywordAreaHeight: CGFloat = 78

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

            Spacer().frame(height: 16)

            WSSFlowLayout(
                horizontalSpacing: 6,
                verticalSpacing: 8
            ) {
                ForEach(keywords(for: category)) { keyword in
                    CapsuleSelectableKeywordChip(keyword: keyword.name,
                                                 isSelected: false,
                                                 action: { })
                }
            }
            .frame(height: isExpanded ? nil : collapsedKeywordAreaHeight, alignment: .top)
            .clipped()
            .padding(.horizontal, 20)

            Spacer().frame(height: 34)

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
    SearchKeywordView(viewModel: SearchKeywordViewModel(loadTotalKeywordsUseCase: PreviewLoadTotalKeywordsUseCase()))
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
