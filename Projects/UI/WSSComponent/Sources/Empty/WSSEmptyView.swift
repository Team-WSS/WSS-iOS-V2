//
//  WSSEmptyView.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 6/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import DesignSystem

public struct WSSEmptyView: View {
    let type: WSSEmptyType
    let action: (() -> Void)?

    /// - Parameter action: CTA 버튼 탭 콜백. **생략하면 버튼을 그리지 않는다** —
    ///   유도할 행동이 없는 빈 상태(알림 목록 등)를 화면마다 다시 그리지 않게 하려는 것이다.
    ///   `type.buttonTitle`이 nil이어도 버튼은 나오지 않는다(문구만 있는 타입).
    public init(type: WSSEmptyType,
                action: (() -> Void)? = nil) {
        self.type = type
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 0) {
            WSSImage.imgEmpty.swiftUIImage

            Spacer().frame(height: 8)

            Text(type.description)
                .applyWSSFont(.body1)
                .foregroundStyle(WSSColor.wssGray200.swiftUIColor)
                .multilineTextAlignment(.center)

            // 카피와 콜백이 모두 있을 때만 CTA를 그린다 — 둘 중 하나만 있으면 누를 수 없는 버튼이거나
            // 이름 없는 버튼이 되므로 아예 내지 않는다(간격도 함께 사라진다).
            if let buttonTitle = type.buttonTitle, let action {
                Spacer().frame(height: 36)

                Button {
                    action()
                } label: {
                    Text(buttonTitle)
                        .applyWSSFont(.title2)
                        .foregroundStyle(WSSColor.wssPrimary100.swiftUIColor)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 41)
                        .background(WSSColor.wssPrimary50.swiftUIColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("CTA 있음") {
    WSSEmptyView(type: .novelNotification,
                 action: { print("버튼 클릭") })
}

#Preview("CTA 없음") {
    WSSEmptyView(type: .notification)
}
