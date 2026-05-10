//
//  PreferenceKeywordChip.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct PreferenceKeywordChip: View {
    private let keyword: String
    private let count: Int

    public init(keyword: String, count: Int) {
        self.keyword = keyword
        self.count = count
    }

    public var body: some View {
        Text("\(keyword) \(count)")
            .applyWSSFont(.body2, color: .wssPrimary100)
            .fixedSize()
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(Color.wssPrimary50)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    VStack(spacing: 8) {
        PreferenceKeywordChip(keyword: "궁중암투", count: 3)
        PreferenceKeywordChip(keyword: "긴 키워드 텍스트", count: 128)
    }
    .padding()
}
