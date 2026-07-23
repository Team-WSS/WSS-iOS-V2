//
//  WSSAlertViewModifier.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import DesignSystem

public struct WSSAlertViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    let alertType: WSSAlertType
    let buttonActions: [() -> Void]

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    // 신고 확인 → 접수 완료처럼 `isPresented`는 그대로 두고 `alertType`만
                    // 바뀌는 다단계 알럿이 있다 — `.id`로 뷰 정체성을 갈라줘야 다음 알럿이
                    // 스냅되지 않고 이전 알럿과 크로스페이드된다.
                    WSSAlertView(
                        type: alertType,
                        buttonActions: buttonActions
                    )
                    .id(alertType)
                    .padding(.horizontal, 42)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isPresented)
            .animation(.easeInOut(duration: 0.25), value: alertType)
    }
}
