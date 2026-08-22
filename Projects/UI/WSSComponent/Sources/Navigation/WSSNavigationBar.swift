//
//  WSSNavigationBar.swift
//  WSSComponent
//
//  Created by YunhakLee on 8/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

/// 커스텀 네비게이션 바 — 뒤로가기 + 가운데 타이틀.
///
/// 시스템 네비바 대신 쓰는 이유는 **폰트와 back 아이콘이 디자인과 다르기 때문**이고,
/// 그 대가로 호출부는 `.toolbar(.hidden, for: .navigationBar)` + `.enableSwipeBack()`을 함께 걸어야 한다
/// (네비바를 숨기면 iOS가 스와이프 뒤로가기도 함께 끈다).
///
/// - Parameters:
///   - title: 가운데 타이틀. 대상의 이름이 아니라 **화면 이름**을 넣는다(예: "알림", "서재").
///   - onBack: 뒤로가기 탭 콜백. 보통 호출부의 `@Environment(\.dismiss)`를 넘긴다 —
///     어디로 가는지는 화면이 정한다(컴포넌트는 내비게이션 정책을 모른다).
public struct WSSNavigationBar: View {

    private enum Metric {
        /// 시스템 네비바(inline)와 같은 높이.
        static let barHeight: CGFloat = 44
        /// 애플 권장 탭 타깃(44)에 맞춘 히트 영역.
        static let backButtonSize: CGFloat = 44
        static let backIconSize: CGFloat = 24
        /// 디자인의 뒤로가기는 화면 왼쪽 끝이 아니라 6pt 안쪽에서 시작한다.
        static let backButtonLeading: CGFloat = 6
    }

    private let title: String
    private let onBack: () -> Void

    public init(title: String, onBack: @escaping () -> Void) {
        self.title = title
        self.onBack = onBack
    }

    public var body: some View {
        // 타이틀을 ZStack 중앙에 두는 건 의도다 — HStack에 넣으면 뒤로가기 버튼 폭만큼 오른쪽으로 밀린다.
        ZStack {
            Text(title)
                .applyWSSFont(.title2, color: .wssBlack)

            HStack(spacing: 0) {
                Button(action: onBack) {
                    WSSImage.icNavigateLeft.swiftUIImage
                        // ⚠️ 이 에셋의 원색은 연회색(#C7C7D0)이라 그대로 쓰면 디자인의 검정 화살표보다 훨씬 흐리다
                        // (DesignSystem의 "아이콘 SVG는 원색 고정") → template으로 색을 입힌다.
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.wssBlack)
                        .frame(width: Metric.backIconSize, height: Metric.backIconSize)
                        // 아이콘 24를 44 히트 영역 가운데 둔다.
                        .frame(width: Metric.backButtonSize, height: Metric.backButtonSize)
                        .contentShape(Rectangle())
                }
                Spacer()
            }
            // ⚠️ `.padding(.horizontal,)`을 쓰지 말 것 — 양쪽에 걸려 반대편 요소까지 민다.
            .padding(.leading, Metric.backButtonLeading)
        }
        .frame(height: Metric.barHeight)
    }
}

#Preview {
    VStack(spacing: 0) {
        WSSNavigationBar(title: "알림") { print("뒤로가기") }
        Spacer()
    }
}
