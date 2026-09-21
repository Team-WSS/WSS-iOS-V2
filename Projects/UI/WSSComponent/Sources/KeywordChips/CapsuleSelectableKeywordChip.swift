//
//  CapsuleSelectableKeywordChip.swift
//  WSSComponent
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct CapsuleSelectableKeywordChip: View {
    private let keyword: String
    private let isSelected: Bool
    private let action: () -> Void

    /// **색 전환만** 애니메이트하기 위한 로컬 미러. 위치(부모 레이아웃)는 `isSelected`가 즉시 확정하고,
    /// 색은 이 값이 `onChange`에서 **한 박자 뒤** 따라와 `.animation(value: animatedSelected)`로 spring한다.
    /// ⚠️ `.animation(value: isSelected)`로 직접 걸면 색뿐 아니라 **위치 변화까지** 애니메이트된다 —
    /// 선택 순간 상위에 선택 칩 행이 생겨 이 칩이 아래로 밀릴 때, 형제 칩은 즉시 새 자리로 가는데
    /// **방금 누른 칩만** 그 하강을 spring으로 뒤늦게 따라와 "잔상"으로 보인다(서재 필터 시트에서 실측).
    /// 미러를 두면 위치는 즉시 스냅되고(그 프레임엔 `animatedSelected` 변화가 없어 애니메이션 대상이 아님)
    /// 다음 프레임에 색만 제자리에서 spring한다.
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
            .applyWSSFont(.body3, color: animatedSelected ? .wssPrimary100 : .wssGray300)
            .fixedSize()
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(animatedSelected ? Color.wssPrimary50 : Color.wssGray50)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            // strokeBorder(= 안쪽으로 그림). stroke는 선의 절반이 프레임 밖으로 나가 상위 ScrollView 클립에 잘린다.
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.wssPrimary100, lineWidth: 1)
                    .opacity(animatedSelected ? 1 : 0)
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: animatedSelected)
            .onTapGesture {
                action()
            }
            // 위치가 이미 확정된 다음 프레임에 색 미러만 갱신 → 색만 spring, 위치는 스냅.
            .onChange(of: isSelected) { _, newValue in
                animatedSelected = newValue
            }
    }
}

#Preview {
    @Previewable @State var selected1 = false
    @Previewable @State var selected2 = true

    HStack(spacing: 8) {
        CapsuleSelectableKeywordChip(keyword: "환생물", isSelected: selected1, action: { selected1.toggle() })
        CapsuleSelectableKeywordChip(keyword: "환생여주", isSelected: selected2, action: { selected2.toggle() })
    }
    .padding()
}
