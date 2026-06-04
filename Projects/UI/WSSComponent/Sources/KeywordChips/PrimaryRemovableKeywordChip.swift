//
//  PrimaryRemovableKeywordChip.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct PrimaryRemovableKeywordChip: View {
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
        HStack(spacing: 10) {
            Text(keyword)
                .applyWSSFont(.body3, color: .wssPrimary100)
                .fixedSize()

            WSSImage.icKeywordCancel.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 6)
        .background(Color.wssPrimary50)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.wssPrimary100, lineWidth: 1))
        .contentShape(Capsule())
        .onTapGesture { action() }
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryRemovableKeywordChip(keyword: "후회", action: {
            print("칩 클릭")
        })
        PrimaryRemovableKeywordChip(keyword: "긴 키워드 텍스트 예시", action: {
            print("칩 클릭")
        })
    }
    .padding()
}
