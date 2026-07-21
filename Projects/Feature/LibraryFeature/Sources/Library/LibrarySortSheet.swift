//
//  LibrarySortSheet.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import NovelDomain
import DesignSystem
import WSSComponent

// 정렬 선택 바텀시트 — 6종 중 단일 선택. 선택 즉시 부모가 dismiss + 재로드한다.
struct LibrarySortSheet: View {

    let selected: LibrarySortType
    let onSelect: (LibrarySortType) -> Void

    static let sheetHeight: CGFloat = 24 + 6 * 39 + 5 * 10 + 24

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)
            ForEach(Array(LibrarySortType.allCases.enumerated()), id: \.element) { index, sortType in
                if index > 0 {
                    Spacer().frame(height: 10)
                }
                row(sortType)
            }
            Spacer()
        }
    }

    private func row(_ sortType: LibrarySortType) -> some View {
        let isSelected = sortType == selected
        return Button {
            onSelect(sortType)
        } label: {
            HStack(spacing: 4) {
                if isSelected {
                    WSSImage.icCheckMark.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }
                Text(sortType.libraryDisplayName)
                    .applyWSSFont(.body2, color: isSelected ? .wssBlack : .wssGray200)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 39)
            .background(isSelected ? Color.wssPrimary20 : Color.wssWhite)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    LibrarySortSheet(selected: .title) { print("정렬 선택: \($0)") }
}
