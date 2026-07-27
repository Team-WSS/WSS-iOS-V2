//
//  LibrarySection.swift
//  UserPageFeature
//
//  Created by Seoyeon Choi on 7/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem
import NovelDomain

/// MyPage·UserPage 공용 서재 통계 섹션. 화면별로 배경·카운트 컬러만 다를 수 있어 파라미터로 둔다.
struct LibrarySection: View {

    let stats: RegisteredNovelStats?
    var backgroundColor: Color = WSSColor.wssPrimary20.swiftUIColor
    var countColor: Color = WSSColor.wssPrimary100.swiftUIColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                libraryItem(count: stats?.interest ?? 0, title: "관심")
                libraryItem(count: stats?.watching ?? 0, title: "보는중")
                libraryItem(count: stats?.watched ?? 0, title: "봤어요")
                libraryItem(count: stats?.quit ?? 0, title: "하차")
            }
            .padding(.vertical, 14.5)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }

    private func libraryItem(count: Int, title: String) -> some View {
        VStack(spacing: 2) {
            Text(String(count))
                .applyWSSFont(.title2)
                .foregroundStyle(countColor)
                .lineLimit(1)

            Text(title)
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
        }
        .frame(maxWidth: .infinity)
    }
}
