//
//  FilterKeywordChip.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct FilterKeywordChip: View {
    private let keyword: String
    private let isSelected: Bool
    private let onTap: () -> Void

    public init(
        keyword: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) {
        self.keyword = keyword
        self.isSelected = isSelected
        self.onTap = onTap
    }

    public var body: some View {
        Text(keyword)
            .applyWSSFont(.body3, color: isSelected ? .wssPrimary100 : .wssGray300)
            .fixedSize()
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(isSelected ? Color.wssPrimary50 : Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.wssPrimary100, lineWidth: 1)
                    .opacity(isSelected ? 1 : 0)
            )
            .onTapGesture { onTap() }
    }
}

#Preview {
    @Previewable @State var selected1 = false
    @Previewable @State var selected2 = true

    HStack(spacing: 8) {
        FilterKeywordChip(keyword: "환생물", isSelected: selected1, onTap: { selected1.toggle() })
        FilterKeywordChip(keyword: "환생여주", isSelected: selected2, onTap: { selected2.toggle() })
    }
    .padding()
}
