//
//  WSSFilterButton.swift
//  WSSComponent
//
//  Created by YunhakLee on 5/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import SwiftUI
import DesignSystem

public struct WSSFilterButton: View {
    let text: String
    var isImageHidden: Bool = false
    var isSelected: Bool = false
    var action: () -> Void
    
    public init(text: String, isImageHidden: Bool, isSelected: Bool, action: @escaping () -> Void) {
        self.text = text
        self.isImageHidden = isImageHidden
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(text)
                    .applyWSSFont(.body4)
                
                if !isImageHidden {
                    WSSImage.icDropdownfill.swiftUIImage
                }
            }
            .padding(.horizontal, 13)
            .frame(height: 33)
            .foregroundColor(isSelected ? WSSColor.wssWhite.swiftUIColor : WSSColor.wssGray300.swiftUIColor)
            .background(isSelected ? WSSColor.wssBlack.swiftUIColor : WSSColor.wssWhite.swiftUIColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? WSSColor.wssBlack.swiftUIColor : WSSColor.wssGray80.swiftUIColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        WSSFilterButton(text: "매력포인트", isImageHidden: false, isSelected: false) {
            print("매력포인트")
        }
        
        WSSFilterButton(text: "매력포인트", isImageHidden: false, isSelected: true) {
            print("매력포인트")
        }
        
        WSSFilterButton(text: "텍스트만", isImageHidden: true, isSelected: false) {
            print("텍스트만")
        }
        
        WSSFilterButton(text: "텍스트만", isImageHidden: true, isSelected: true) {
            print("텍스트만")
        }
    }
    .padding()
}
