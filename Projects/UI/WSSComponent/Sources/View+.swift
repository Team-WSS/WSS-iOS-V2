//
//  View+.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

public extension View {
    func showWSSToast(isPresented: Binding<Bool>,
                      type: WSSToastType,
                      duration: Double = 3.0) -> some View {
        self.modifier(
            WSSToastViewModifier(isPresented: isPresented,
                          type: type,
                          duration: duration)
        )
    }
    
    func showWSSAlert(isPresented: Binding<Bool>,
                      type: WSSAlertType,
                      leftButtonTapped: (() -> Void)? = nil,
                      rightButtonTapped: @escaping () -> Void) -> some View {
        self.modifier(
            WSSAlertViewModifier(isPresented: isPresented,
                                 alertType: type,
                                 leftButtonTapped: leftButtonTapped,
                                 rightButtonTapped: rightButtonTapped)
        )
    }
}
