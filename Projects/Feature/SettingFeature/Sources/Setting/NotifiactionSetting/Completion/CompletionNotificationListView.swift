//
//  CompletionNotificationListView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import WSSComponent

import NovelDomain

struct CompletionNotificationListView: View {
    @Environment(\.dismiss) private var dismiss
    let novelList: [String]
    
    var body: some View {
        ZStack(alignment: .center) {
            if novelList.isEmpty {
                VStack(spacing: 0) {
                    WSSEmptyView(type: .novelNotification,
                                 action: { print("일반 검색으로 이동") })
                }
            } else {
                ScrollView {
                    VStack(spacing: 6){
                        ForEach(0..<10, id: \.self) { _ in
                            NovelNotificationRow()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .toolbar {
            toolbarContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}

// MARK: - Toolbar

private extension CompletionNotificationListView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                WSSImage.icNavigateLeft.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
        }

        ToolbarItem(placement: .principal) {
            Text("완결 알림")
                .applyWSSFont(.title2)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }
        
        if !novelList.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Text("수정")
                    .applyWSSFont(.title2)
                    .foregroundStyle(WSSColor.wssGray300.swiftUIColor)
            }
        }
    }
}


#Preview {
    NavigationStack {
        CompletionNotificationListView(novelList: [
            "", "", "", ""
            ])
    }
}
