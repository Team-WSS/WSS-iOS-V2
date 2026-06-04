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
    private let action: () -> Void

    public init(
        keyword: String,
        action: @escaping () -> Void
    ) {
        self.keyword = keyword
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 6) {
            Text(keyword)
                .applyWSSFont(.body3, color: .wssPrimary100)
                .fixedSize()

            WSSImage.icKeywordCancel.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 5)
        .background(Color.wssWhite)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.wssPrimary100, lineWidth: 1))
        .contentShape(Capsule())
        .onTapGesture { action() }
    }
}

#Preview {
    VStack(spacing: 12) {
        WhiteRemovableKeywordChip(keyword: "환생물", action: {
            print("칩 클릭")
        })
        WhiteRemovableKeywordChip(keyword: "긴 키워드 텍스트 예시", action: {
            print("칩 클릭")
        })
    }
    .padding()
}
