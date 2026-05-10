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
    let leftButtonTapped: (() -> Void)?
    let rightButtonTapped: () -> Void

    public init(
        type: WSSAlertType,
        leftButtonTapped: (() -> Void)? = nil,
        rightButtonTapped: @escaping () -> Void
    ) {
        self.type = type
        self.leftButtonTapped = leftButtonTapped
        self.rightButtonTapped = rightButtonTapped
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
                if let leftButton = type.content.leftButton {
                    WSSAlertButton(content: leftButton)
                        .onTapGesture { leftButtonTapped?() }
                }

                WSSAlertButton(content: type.content.rightButton)
                    .onTapGesture { rightButtonTapped() }
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
    
    private struct WSSAlertButton: View {
        let content: WSSAlertButtonContent
        
        var body: some View {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Spacer()
                    Text(content.title)
                        .applyWSSFont(.body4)
                        .foregroundStyle(content.textColor)
                    Spacer()
                }
            }
            .padding(.vertical, 10.5)
            .background(content.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    WSSAlertView(
        type: .receivedReportSpoilerContent,
        rightButtonTapped: { print("확인 클릭") }
    )
}
