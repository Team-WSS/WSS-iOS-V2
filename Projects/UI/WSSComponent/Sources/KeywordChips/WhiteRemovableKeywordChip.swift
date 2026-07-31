//
//  WhiteRemovableKeywordChip.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct WhiteRemovableKeywordChip: View {
    private let keyword: String
    private let onSelect: () -> Void
    private let onDelete: () -> Void

    public init(
        keyword: String,
        onSelect: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.keyword = keyword
        self.onSelect = onSelect
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: 6) {
            Text(keyword)
                .applyWSSFont(.body3, color: .wssPrimary100)
                .fixedSize()

            Button(action: onDelete) {
                WSSImage.icKeywordCancel.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 5)
        .background { Capsule().fill(Color.wssWhite) }
        .overlay { Capsule().strokeBorder(Color.wssPrimary100, lineWidth: 1) }
        .contentShape(Capsule())
        .onTapGesture { onSelect() }
    }
}

#Preview {
    VStack(spacing: 12) {
        WhiteRemovableKeywordChip(keyword: "환생물", onSelect: {
            print("키워드로 검색")
        }, onDelete: {
            print("삭제")
        })
        WhiteRemovableKeywordChip(keyword: "긴 키워드 텍스트 예시", onSelect: {
            print("키워드로 검색")
        }, onDelete: {
            print("삭제")
        })
    }
    .padding()
}
