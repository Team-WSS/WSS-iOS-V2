//
//  WSSResetButton.swift
//  WSSComponent
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

/// 필터류 화면 하단 액션바의 "초기화" 보조 버튼. 항상 `WSSCTAButton`("작품 찾기" 등)과 나란히 쓰인다 —
/// 라벨·아이콘·크기·색은 두 화면(`SearchFeature`의 상세탐색 필터, `LibraryFeature`의 서재 필터 시트)이
/// 완전히 같은 값으로 손으로 복제하고 있어 승격했다(2026-08). 무엇을 초기화할지(현재 탭만/시트 전체)는
/// 호출부의 `action`이 정한다 — 이 컴포넌트는 표시만 갖고 정책을 모른다.
public struct WSSResetButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                WSSImage.icReset.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                Text("초기화")
                    .applyWSSFont(.title2, color: .wssGray200)
            }
            .frame(width: 95, height: 53)
            .background(Color.wssWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.wssGray80, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 10) {
        WSSResetButton { print("초기화") }
        WSSCTAButton(title: "작품 찾기") { print("작품 찾기") }
    }
    .padding(.horizontal, 16)
}
