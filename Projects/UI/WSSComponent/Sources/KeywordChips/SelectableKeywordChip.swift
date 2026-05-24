//
//  SelectableKeywordChip.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct SelectableKeywordChip: View {
    private let keyword: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(
        keyword: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.keyword = keyword
        self.isSelected = isSelected
        self.action = action
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
            .onTapGesture { action() }
    }
}

#Preview {
    @Previewable @State var selected1 = false
    @Previewable @State var selected2 = true

    HStack(spacing: 8) {
        SelectableKeywordChip(keyword: "환생물", isSelected: selected1, action: { selected1.toggle() })
        SelectableKeywordChip(keyword: "환생여주", isSelected: selected2, action: { selected2.toggle() })
    }
    .padding()
}
