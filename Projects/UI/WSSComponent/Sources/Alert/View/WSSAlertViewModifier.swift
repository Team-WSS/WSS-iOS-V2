//
//  WSSAlertViewModifier.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI
import UIKit
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
            // 알럿이 화면 위 키보드를 가리는 걸 막는다. 호출부마다 어떤 필드가 포커스인지
            // 몰라도 되도록, 퍼스트 리스폰더에게 직접 resign을 보내는 전역 트릭을 쓴다.
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
    }
}
