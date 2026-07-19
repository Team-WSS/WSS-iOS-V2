//
//  SettingMenuRow.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/15/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

struct SettingMenuRow: View {
    let title: String
    var bottomText: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .applyWSSFont(.body2)
                        .foregroundStyle(Color.wssBlack)
                    
                    if let bottomText {
                        Text(bottomText)
                            .applyWSSFont(.body3)
                            .foregroundStyle(Color.wssGray200)
                    }
                }
                
                Spacer()
                
                if action != nil {
                    WSSImage.icNavigateRight.swiftUIImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.vertical, bottomText == nil ? 20 : 9.5)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
            .onTapGesture {
                action?()
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(WSSColor.wssGray50.swiftUIColor)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        SettingMenuRow(title: "약관보기") {}
        
        SettingMenuRow(title: "버전정보", bottomText: "1.0.0")
        
        SettingMenuRow(title: "로그아웃") {}
        
        SettingMenuRow(title: "회원탈퇴") {}
        
    }
}
