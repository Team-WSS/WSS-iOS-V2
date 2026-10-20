//
//  CollectionTooltip.swift
//  WSS-iOS
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 탭바 바로 위에서 My 탭을 가리키는 "나만의 컬렉션을 만들어보세요" 툴팁(#283).
/// 노출·확인 판정은 `MainTabView`가 하고, 이 파일은 그리기와 위치만 맡는다.
private struct CollectionTooltip: View {

    enum Metric {
        static let size = CGSize(width: 186, height: 44)
        /// 말풍선 몸통 높이 — 나머지 6pt는 아래로 튀어나온 꼬리.
        static let bodyHeight: CGFloat = 38
        /// 말풍선 오른쪽 끝 ↔ 꼬리 끝(가운데) 거리. 에셋 원본(회전 전)의 꼬리 중심 x≈31.5.
        static let tailFromTrailing: CGFloat = 31.5
    }

    var body: some View {
        Text("나만의 컬렉션을 만들어보세요")
            .applyWSSFont(.body3, color: .wssWhite)
            .frame(width: Metric.size.width, height: Metric.bodyHeight)
            .frame(width: Metric.size.width, height: Metric.size.height, alignment: .top)
            .background {
                // Figma 원본 에셋은 꼬리가 위·왼쪽이고 화면에선 180° 돌려 배치돼 있다 — 돌리면 꼬리가 아래·오른쪽(My 탭 쪽).
                WSSImage.icCollectionTooltip.swiftUIImage
                    .resizable()
                    .rotationEffect(.degrees(180))
            }
    }
}

extension View {
    /// 탭 Root의 **NavigationStack 루트 콘텐츠**에 건다 — 루트 콘텐츠의 하단 safe area가 곧 탭바 상단이라
    /// 탭바 위에 붙고, push 화면(탭바 숨김)에선 그 화면에 덮여 자연히 안 보인다.
    func collectionTooltip(isPresented: Bool) -> some View {
        overlay {
            if isPresented {
                GeometryReader { proxy in
                    CollectionTooltip()
                        .padding(.trailing, collectionTooltipTrailingInset(containerWidth: proxy.size.width))
                        .padding(.bottom, 13)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
                // 아래 콘텐츠 탭을 막지 않는다 — 툴팁 자체엔 탭 동작이 없다.
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
    }
}

/// 꼬리 끝이 My 탭 중심에 오도록 하는 말풍선의 오른쪽 여백.
/// ⚠️ 시스템 탭바의 아이템 위치를 SwiftUI로 읽을 방법이 없어 화면 너비로 계산한다 — Figma의 고정 여백(20)은
/// 화면을 4등분하는 예전 탭바 기준이라, 떠 있는 iOS 26 탭바에선 꼬리가 My 오른쪽으로 크게 벗어났다.
/// - iOS 26+: 탭바가 화면 양옆에서 21pt 들어와 떠 있고 그 안쪽 11pt를 뺀 폭을 4등분한다
///   (iPhone 17 Pro Max 실측 — 아이템 중심 78.5/172.5/266.5/360.5pt, 간격 94pt).
/// - iOS 17~18: 탭바가 화면 폭을 4등분한다.
private func collectionTooltipTrailingInset(containerWidth: CGFloat) -> CGFloat {
    let myTabCenterFromTrailing: CGFloat
    if #available(iOS 26.0, *) {
        let barInset: CGFloat = 21 + 11
        myTabCenterFromTrailing = barInset + (containerWidth - barInset * 2) / 8
    } else {
        myTabCenterFromTrailing = containerWidth / 8
    }
    return myTabCenterFromTrailing - CollectionTooltip.Metric.tailFromTrailing
}
