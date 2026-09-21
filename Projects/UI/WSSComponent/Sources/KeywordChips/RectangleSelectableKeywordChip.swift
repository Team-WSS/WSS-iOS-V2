//
//  RectangleSelectableKeywordChip.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct RectangleSelectableKeywordChip: View {
    private let keyword: String
    private let isSelected: Bool
    private let action: () -> Void

    /// **색 전환만** 애니메이트하기 위한 로컬 미러 — `CapsuleSelectableKeywordChip`과 같은 이유·같은 방식이다.
    /// 위치(부모 레이아웃)는 `isSelected`가 즉시 확정하고, 색은 이 값이 `onChange`에서 **한 박자 뒤** 따라와
    /// spring한다. `.animation(value: isSelected)`로 직접 걸면 선택 순간 상위에 칩 행이 생겨 이 칩이 밀릴 때
    /// **위치까지** 애니메이트돼 "방금 누른 칩만 뒤늦게 미끄러지는 잔상"이 생긴다(서재 필터 연재상태 탭).
    @State private var animatedSelected: Bool

    public init(
        keyword: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.keyword = keyword
        self.isSelected = isSelected
        self.action = action
        self._animatedSelected = State(initialValue: isSelected)
    }

    public var body: some View {
        Text(keyword)
            .applyWSSFont(.body2, color: animatedSelected ? .wssPrimary100 : .wssGray300)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(animatedSelected ? Color.wssPrimary50 : Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            // strokeBorder(= 안쪽으로 그림). stroke는 선의 절반이 프레임 밖으로 나가 상위 ScrollView 클립에 잘린다.
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.wssPrimary100, lineWidth: 1)
                    .opacity(animatedSelected ? 1 : 0)
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: animatedSelected)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture { action() }
            // 위치가 이미 확정된 다음 프레임에 색 미러만 갱신 → 색만 spring, 위치는 스냅.
            .onChange(of: isSelected) { _, newValue in
                animatedSelected = newValue
            }
    }
}

#Preview {
    @Previewable @State var isCompleted = true

    HStack(spacing: 11) {
        RectangleSelectableKeywordChip(keyword: "연재중", isSelected: !isCompleted, action: { isCompleted = false })
        RectangleSelectableKeywordChip(keyword: "완결작", isSelected: isCompleted, action: { isCompleted = true })
    }
    .padding(.horizontal, 20)
}
