//
//  NormalSearchAutoCompletionView.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import SearchDomain
import DesignSystem

struct NormalSearchAutoCompletionView: View {

    let searchText: String
    let words: [SearchAutoCompletionWord]
    let onSelect: (SearchAutoCompletionWord) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(words, id: \.word) { word in
                    Button {
                        onSelect(word)
                    } label: {
                        autoCompletionWordRow(text: word.word)
                            .contentShape(Rectangle())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    private func autoCompletionWordRow(text: String) -> some View {
        HStack(spacing: 10) {
            WSSImage.icSearch.swiftUIImage
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
                .frame(width: 17, height: 17)

            highlightedText(text)
                .applyWSSFont(.body3)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    /// 검색 중인 텍스트와 일치하는 첫 구간만 primary100으로 칠한다(대소문자 무시).
    private func highlightedText(_ text: String) -> Text {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty,
              let range = text.range(of: trimmedQuery, options: .caseInsensitive) else {
            return Text(text).foregroundColor(WSSColor.wssBlack.swiftUIColor)
        }

        return Text(text[..<range.lowerBound]).foregroundColor(WSSColor.wssBlack.swiftUIColor)
            + Text(text[range]).foregroundColor(WSSColor.wssPrimary100.swiftUIColor)
            + Text(text[range.upperBound...]).foregroundColor(WSSColor.wssBlack.swiftUIColor)
    }
}

#Preview {
    NormalSearchAutoCompletionView(
        searchText: "고양이",
        words: [
            SearchAutoCompletionWord(word: "고양이고양이고이고양이고양이"),
            SearchAutoCompletionWord(word: "고양이")
        ],
        onSelect: { _ in }
    )
}
