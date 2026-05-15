//
//  WSSAlertView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct WSSAlertView: View {
    let type: WSSAlertType
    let buttonActions: [() -> Void]

    public init(
        type: WSSAlertType,
        buttonActions: [() -> Void] = []
    ) {
        self.type = type
        self.buttonActions = buttonActions
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 아이콘 이미지
            if let iconImage = type.content.iconImage {
                iconImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 46, height: 46)
                    .padding(.bottom, 18)
            }
            
            // 제목
            Text(type.content.title)
                .applyWSSFont(type.content.titleFont)
                .foregroundStyle(Color.wssBlack)
                .multilineTextAlignment(.center)
                .padding(.bottom, type.content.titleBottomPadding)
            
            // 부제목
            if let subtitle = type.content.subtitle,
               let subtitleFont = type.content.subtitleFont,
               let subtitleColor = type.content.subtitleColor,
               let padding = type.content.subTitlePadding {
                Text(subtitle)
                    .applyWSSFont(subtitleFont)
                    .foregroundStyle(subtitleColor)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, padding)
            }
            
            // 버튼
            HStack(spacing: 18) {
                ForEach(Array(type.content.buttons.indices),
                        id: \.self) { index in
                    WSSAlertButtonView(content: type.content.buttons[index])
                        .onTapGesture {
                            if index < buttonActions.count {
                                buttonActions[index]()
                            }
                        }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 21)
        .background(Color.wssWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1),
                radius: 5,
                x: 0,
                y: 2)
    }
    
    private struct WSSAlertButtonView: View {
        let content: WSSAlertButton
        
        var body: some View {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer()
                    Text(content.title)
                        .applyWSSFont(.body4)
                        .foregroundStyle(content.role.textColor)
                    Spacer()
                }
            }
            .padding(.vertical, 10.5)
            .background(content.role.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    WSSAlertView(
        type: .receivedReportSpoilerContent,
        buttonActions: [{ print("확인 클릭") }]
    )
}
