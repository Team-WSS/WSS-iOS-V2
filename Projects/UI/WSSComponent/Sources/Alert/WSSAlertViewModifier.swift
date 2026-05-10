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
    let leftButtonTapped: (() -> Void)?
    let rightButtonTapped: () -> Void

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    WSSAlertView(
                        type: alertType,
                        leftButtonTapped: leftButtonTapped,
                        rightButtonTapped: rightButtonTapped
                    )
                    .padding(.horizontal, 42)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.easeInOut(duration: 0.25),
                       value: isPresented)
    }
}
