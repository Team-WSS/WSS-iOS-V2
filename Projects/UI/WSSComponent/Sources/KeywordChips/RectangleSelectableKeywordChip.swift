//
//  RectangleSelectableKeywordChip.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct RectangleSelectableKeywordChip: View {
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
            .applyWSSFont(.body2, color: isSelected ? .wssPrimary100 : .wssGray300)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.wssPrimary50 : Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.wssPrimary100, lineWidth: 1)
                    .opacity(isSelected ? 1 : 0)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture { action() }
    }
}

#Preview {
    @Previewable @State var isCompleted = true

    HStack(spacing: 11) {
        RectangleSelectableKeywordChip(keyword: "연재중", isSelected: !isCompleted, action: { isCompleted = false })
        RectangleSelectableKeywordChip(keyword: "완결작", isSelected: isCompleted, action: { isCompleted = true })
    }
    .padding(.horizontal, 20)
}
