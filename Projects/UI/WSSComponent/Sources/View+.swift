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
            ToastModifier(isPresented: isPresented,
                          type: type,
                          duration: duration)
        )
    }
}
