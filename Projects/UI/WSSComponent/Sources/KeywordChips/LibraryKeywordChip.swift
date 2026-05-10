//
//  LibraryKeywordChip.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct LibraryKeywordChip: View {
    private let keyword: String

    public init(keyword: String) {
        self.keyword = keyword
    }

    public var body: some View {
        Text(keyword)
            .applyWSSFont(.body5, color: .wssGray200)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.wssPrimary20)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    HStack(spacing: 8) {
        LibraryKeywordChip(keyword: "빙의")
        LibraryKeywordChip(keyword: "궁중암투")
        LibraryKeywordChip(keyword: "긴 키워드 텍스트")
    }
    .padding()
}
