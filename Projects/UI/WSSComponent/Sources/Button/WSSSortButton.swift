//
//  WSSSortButton.swift
//  WSSComponent
//

import SwiftUI
import DesignSystem
import BaseDomain

public struct WSSSortButton: View {
    let sortType: SortType
    let action: () -> Void

    public init(sortType: SortType, action: @escaping () -> Void) {
        self.sortType = sortType
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                WSSImage.icSwitch.swiftUIImage
                    .frame(width: 16, height: 16)
                Text(sortType.displayName)
                    .applyWSSFont(.body3)
                    .foregroundStyle(Color.wssGray300)
            }
            .frame(height: 33)
            .background(Color.wssWhite)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        WSSSortButton(sortType: .recent) { print("최신 순") }
        WSSSortButton(sortType: .old) { print("오래된 순") }
    }
    .padding()
}
