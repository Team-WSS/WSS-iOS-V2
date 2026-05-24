//
//  WSSToastView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct WSSToastView: View {
    let type: WSSToastType
    
    public init(type: WSSToastType) {
        self.type = type
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                type.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
    
                Text(type.text)
                    .foregroundStyle(Color.wssGray50)
                    .applyWSSFont(.body1)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
        }
        .background(Color.wssGrayToast)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    WSSToastView(type: .changeInfo)
}
