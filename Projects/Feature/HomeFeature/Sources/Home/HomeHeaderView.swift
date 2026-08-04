//
//  HomeHeaderView.swift
//  HomeFeature
//
//  Created by YunhakLee on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 홈 최상단 고정 헤더 — 로고 + 알림 벨.
/// **스크롤과 무관하게 박혀 있고**, 로딩·실패로 본문이 통째로 대체돼도 이 줄만은 남는다.
struct HomeHeaderView: View {

    let hasUnreadNotifications: Bool
    let onNotificationTapped: () -> Void

    private enum Metric {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 10
        static let logoWidth: CGFloat = 92
        static let logoHeight: CGFloat = 30
        static let bellSize: CGFloat = 28
    }

    var body: some View {
        HStack(spacing: 0) {
            WSSImage.imgLogoType.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: Metric.logoWidth, height: Metric.logoHeight)

            Spacer()

            Button(action: onNotificationTapped) {
                // 안 읽은 알림은 별도 배지 뷰가 아니라 점이 박힌 에셋 variant로 표현한다(디자인 컴포넌트 그대로).
                (hasUnreadNotifications
                 ? WSSImage.icAnnouncementDotted.swiftUIImage
                 : WSSImage.icAnnouncement.swiftUIImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metric.bellSize, height: Metric.bellSize)
            }
        }
        .padding(.horizontal, Metric.horizontalPadding)
        .padding(.vertical, Metric.verticalPadding)
        .background(Color.wssWhite)
    }
}
