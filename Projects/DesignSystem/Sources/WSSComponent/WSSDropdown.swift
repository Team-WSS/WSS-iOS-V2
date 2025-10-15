//
//  WSSDropdown.swift
//  DesignSystem
//
//  Created by Seoyeon Choi on 10/15/25.
//

import SwiftUI

public struct WSSDropdown: View {
    public let action: () -> Void
    
    public init(action: @escaping () -> Void = {}) {
        self.action = action
    }
    
    public var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 0) {
                Text("차단하기")
                    .wssFont(.body2)
                    .foregroundStyle(WSSColor.black)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 34)
            .background(WSSColor.white)
            .frame(width: 120)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: WSSColor.black.opacity(0.11),
                radius: 15,
                x: 0,
                y: 2
            )
        }
    }
}

#Preview {
    WSSDropdown()
}
