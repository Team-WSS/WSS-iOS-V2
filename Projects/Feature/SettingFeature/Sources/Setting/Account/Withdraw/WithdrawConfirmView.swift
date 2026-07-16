//
//  WithdrawConfirmView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

import BaseDomain

struct WithdrawConfirmView: View {

    private let stateColumnCount = 2
    private let statelItemSpacing: CGFloat = 6
    private let stateColumnSpacing: CGFloat = 6
    /// "확인" 탭 시 호출된다. 실제 탈퇴 제출은 다음 화면(`WithdrawReasonView`)의 책임이라
    /// 이 화면은 다음 화면으로의 이동 신호만 호출자에게 알린다.
    private let onConfirm: () -> Void

    init(onConfirm: @escaping () -> Void = {}) {
        self.onConfirm = onConfirm
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 45)
                
                Text("정말 탈퇴하시겠어요?")
                    .applyWSSFont(.headline1)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 8)
                
                Text("남겼던 평가와 기록들이 모두 사라져요..")
                    .applyWSSFont(.body2)
                    .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 60)
                
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed((size.width - 46) / 2),
                                            spacing: statelItemSpacing),
                        count: stateColumnCount
                    ),
                    spacing: stateColumnSpacing
                ) {
                    ForEach(ReadingStatus.allCases, id: \.statusName) { status in
                        readingStatesItem(status: status)
                    }
                    readingStatesItem(status: .quit)
                }
                
                Spacer()
                
                WSSCTAButton(title: "확인",
                             action: onConfirm)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
            }
            .toolbar {
                toolbarContent
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func readingStatesItem(status: ReadingStatus) -> some View {
        VStack(spacing: 0) {
            status.strokeImage
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssGray100.swiftUIColor)
                .frame(width: 25, height: 25)
            
            Spacer().frame(height: 5)
            
            Text(status.statusName)
                .applyWSSFont(.title3)
                .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
            
            Text("12")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(WSSColor.wssPrimary20.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Toolbar

extension WithdrawConfirmView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            WSSImage.icNavigateLeft.swiftUIImage
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .frame(width: 24, height: 24)
        }
        
        ToolbarItem(placement: .principal) {
            Text("회원탈퇴")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }
    }
}

#Preview {
    NavigationStack {
        WithdrawConfirmView()
    }
}
