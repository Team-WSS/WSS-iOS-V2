//
//  WSSEmptyView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 6/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

public struct WSSEmptyView: View {
    let type: WSSEmptyType
    let action: () -> Void
    
    public init(type: WSSEmptyType,
                action: @escaping () -> Void) {
        self.type = type
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            WSSImage.imgEmpty.swiftUIImage
            
            Spacer().frame(height: 8)
            
            Text(type.description)
                .applyWSSFont(.body1)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .multilineTextAlignment(.center)
            
            Spacer().frame(height: 36)
            
            Button {
                action()
            } label: {
                Text(type.buttonTitle)
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 41)
                    .background(WSSColor.wssPrimary50.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WSSEmptyView(type: .novelNotification,
                 action: { print("버튼 클릭") })
}
