//
//  NovelNotificationRow.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NotificationDomain
import DesignSystem
import WSSComponent

/// 행 전체가 탭 영역이다 — 체크 아이콘 전환 애니메이션이 자연스럽도록 `Button`이 아니라 `onTapGesture`로
/// 받는다(`WSSComponent`의 `WSSSelectionCheckIcon` 정본 패턴).
struct NovelNotificationRow: View {
    let subscription: NovelNotificationSubscription
    /// 편집 모드가 아니면 체크 버튼 자체가 없다("수정"을 눌러야 나타남) — 탭도 이때만 받는다.
    let isEditing: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            WSSNovelCoverImage(url: subscription.novelThumbnailImage)
                .frame(width: 78, height: 105)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            infoSection

            Spacer(minLength: 0)

            if isEditing {
                selectionIcon
                    .padding(10)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleSelection()
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subscription.novelTitle)
                .applyWSSFont(.title3)
                .foregroundStyle(WSSColor.wssBlack.swiftUIColor)
                .lineLimit(1)

            Text(subscription.novelAuthor)
                .applyWSSFont(.body5_2)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .lineLimit(1)

            Text("\(subscription.registeredDateText) 등록")
                .applyWSSFont(.body5)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .lineLimit(1)
        }
    }

    private var selectionIcon: some View {
        WSSSelectionCheckIcon(isSelected: isSelected)
            .frame(width: 24, height: 24)
    }
}

#Preview {
    VStack(spacing: 6) {
        NovelNotificationRow(
            subscription: NovelNotificationSubscription(
                id: SubscriptionID(1),
                novelID: NovelID(1),
                novelTitle: "당신의 이해를 돕기 위하여",
                novelThumbnailImage: nil,
                novelAuthor: "이보라",
                registeredDateText: "2026.07.03"
            ),
            isEditing: false,
            isSelected: false,
            onToggleSelection: {}
        )

        NovelNotificationRow(
            subscription: NovelNotificationSubscription(
                id: SubscriptionID(2),
                novelID: NovelID(2),
                novelTitle: "여주인공의 오빠를 지키는 방법",
                novelThumbnailImage: nil,
                novelAuthor: "안녕하세요",
                registeredDateText: "2026.06.10"
            ),
            isEditing: true,
            isSelected: true,
            onToggleSelection: {}
        )
    }
    .padding(.horizontal, 20)
}
