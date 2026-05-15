//
//  WSSToastViewModifier.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

public struct WSSToastViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    let type: WSSToastType
    let duration: Double

    public func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                VStack(spacing: 0) {
                    Spacer()
                    WSSToastView(type: type)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
                .padding(.bottom, 40)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}
