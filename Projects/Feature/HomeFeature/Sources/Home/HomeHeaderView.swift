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
        /// ⚠️ **10을 넘기지 말 것** — 벨 히트영역(28 + inset×2)이 헤더 50pt 박스를 넘어가면
        /// 아래 ScrollView를 침범해 검색바 위쪽 탭을 조용히 훔친다.
        static let bellHitInset: CGFloat = 8
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
                    // 28pt 아이콘 하나뿐이라 그대로는 탭 타깃이 작고 비투명 픽셀만 눌린다 → 넓혀준다.
                    // ⚠️ **트레일링에는 주지 않는다** — 헤더 패딩 20이 이미 여백이라, 주면 그만큼 벨이
                    // 왼쪽으로 밀린다. 헤더 패딩을 깎아 상쇄하려 들면 반대쪽 **로고까지 함께 밀린다**
                    // (`.padding(.horizontal,)`은 양쪽에 걸린다 — #179 리뷰에서 실제로 그랬다).
                    .padding(.leading, Metric.bellHitInset)
                    .padding(.vertical, Metric.bellHitInset)
                    .contentShape(Rectangle())
            }
        }
        // ⚠️ 벨의 세로 히트영역(28+16=44)이 헤더 높이를 밀지 못하게 **로고 높이로 고정**한다.
        // 없으면 헤더가 50 → 64로 커지면서 검색바부터 아래 전부가 내려간다(LibraryView와 같은 처리).
        .frame(height: Metric.logoHeight)
        .padding(.horizontal, Metric.horizontalPadding)
        .padding(.vertical, Metric.verticalPadding)
        .background(Color.wssWhite)
    }
}
