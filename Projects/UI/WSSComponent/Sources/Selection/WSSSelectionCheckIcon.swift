//
//  WSSSelectionCheckIcon.swift
//  WSSComponent
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 선택/미선택 체크 아이콘(`icSelectNovelDefault`/`icSelectNovelSelected`) — 전환을 크로스페이드+스케일
/// 스프링(`.spring(response: 0.32, dampingFraction: 0.6)`)으로 통일한다(#188, 여러 화면에 흩어져 있던
/// 같은 구현을 여기 한 곳으로 모음 — 정본은 `CreateFeedConnectNovelRow`).
///
/// 순수 표시 전용이라 탭 제스처를 갖지 않는다 — 호출부가 `Button`/`onTapGesture`로 감싼다. 크기도
/// 정하지 않는다(원본 SVG 크기 그대로 렌더) — 호출부가 필요하면 `.frame(width:height:)`을 얹는다.
public struct WSSSelectionCheckIcon: View {
    private let isSelected: Bool

    public init(isSelected: Bool) {
        self.isSelected = isSelected
    }

    public var body: some View {
        ZStack {
            WSSImage.icSelectNovelDefault.swiftUIImage
                .opacity(isSelected ? 0 : 1)
                .scaleEffect(isSelected ? 0.85 : 1)

            WSSImage.icSelectNovelSelected.swiftUIImage
                .opacity(isSelected ? 1 : 0)
                .scaleEffect(isSelected ? 1 : 0.6)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isSelected = false

    VStack(spacing: 24) {
        WSSSelectionCheckIcon(isSelected: isSelected)
            .frame(width: 44, height: 44)

        WSSSelectionCheckIcon(isSelected: isSelected)
            .frame(width: 24, height: 24)
    }
    .onTapGesture { isSelected.toggle() }
}
