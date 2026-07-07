//
//  WSSEmptyView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 6/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

public enum EmptyType {
    case novel
    case keyword
    
    var description: String {
        switch self {
        case .novel:    "해당 검색어를 가진 작품은\n아직 등록되지 않았어요.."
        case .keyword:  "해당 키워드는\n아직 등록되지 않았어요.."
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .novel: "작품 문의하러 가기"
        case .keyword: "키워드 문의하러 가기"
        }
    }
}

public struct WSSEmptyView: View {
    let type: EmptyType
    let action: () -> Void
    
    public init(type: EmptyType,
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
    WSSEmptyView(type: .novel,
                 action: { print("버튼 클릭") })
}
