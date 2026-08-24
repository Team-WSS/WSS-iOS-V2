//
//  WSSPillBadge.swift
//  WSSComponent
//
//  Created by Guryss on 8/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

/// "+ 추가"/"× 삭제" 같은 짧은 필(pill) 배지. `CollectionFeature`의 작품 추가/삭제(#199)가 원본이고,
/// 다른 화면(작품 알림 해제 등)에서도 같은 룩을 쓸 예정이라 두 번째 필요 시점을 기다리지 않고 미리
/// 승격했다 — 이 배지 자체는 "추가"/"삭제"라는 도메인 의미를 모른다(라벨 텍스트·스타일만 값으로 받음).
public struct WSSPillBadge: View {

    public enum Style: Equatable {
        /// 채워진 배경(`wssPrimary100`) + 흰 글씨. 기본 용례: "+ 추가".
        case add
        /// 옅은 배경(`wssSecondary10`) + 코랄 글씨. 기본 용례: "× 삭제".
        case remove
        
        var label: String {
            switch self {
            case .add:      return "추가"
            case .remove:   return "삭제"
            }
        }
        
        var icon: Image {
            switch self {
            case .add:      return WSSImage.icPillBadgePlus.swiftUIImage
            case .remove:   return WSSImage.icPillBadgeXMark.swiftUIImage
            }
        }
    }

    private let style: Style
    private let action: (() -> Void)?

    /// - Parameter action: `nil`(기본값)이면 순수 표시용 — 부모 뷰가 탭을 처리한다(`CollectionSearchNovelView`
    ///   처럼 행 전체가 탭 영역인 경우). 값을 넘기면 배지 자신이 탭을 받는 단독 액션이 된다.
    public init(style: Style, action: (() -> Void)? = nil) {
        self.style = style
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 0) {
            style.icon
                .resizable()
                .frame(width: 12, height: 12)
            Text(style.label)
        }
        .applyWSSFont(.body5)
        .foregroundStyle(style == .remove ? Color.wssSecondary100 : Color.wssWhite)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background { Capsule().fill(style == .remove ? Color.wssSecondary10 : Color.wssPrimary100) }
        // 미설정 시 기본 크로스페이드가 느리게 번진다(Feature/CLAUDE.md 공통 주의).
        .animation(.easeInOut(duration: 0.1), value: style)
        .contentShape(Capsule())
        .tappable(action)
    }
}

private extension View {

    /// `action`이 있을 때만 자체 탭 제스처를 건다 — `nil`일 때 무조건 `onTapGesture`를 걸면(빈 클로저라도)
    /// 이 뷰가 탭을 소비해버려 부모의 `onTapGesture`(행 전체 탭)로 전파되지 않는다.
    @ViewBuilder
    func tappable(_ action: (() -> Void)?) -> some View {
        if let action {
            onTapGesture(perform: action)
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        WSSPillBadge(style: .add)
        WSSPillBadge(style: .remove, action: { print("단독 삭제 탭") })
    }
    .padding()
}
