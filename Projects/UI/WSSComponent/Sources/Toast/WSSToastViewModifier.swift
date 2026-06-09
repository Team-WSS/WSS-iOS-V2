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
                        .transition(.opacity)
                        .zIndex(1)
                }
                .padding(.bottom, 40)
            }
        }
        // 자동 닫힘 타이머는 토스트 뷰가 아니라 항상 존재하는 ZStack에 붙인다.
        // `if isPresented` 블록의 onAppear에 붙이면, 직전 토스트의 퇴장 트랜지션 도중 재호출 시
        // 빠져나가던 뷰가 재사용돼 onAppear가 다시 안 불려 닫힘이 예약되지 않는다(토스트 영구 잔류).
        // `.task(id:)`는 isPresented 변화마다 이전 sleep을 취소·재시작하므로 재호출에도 견고하다.
        .task(id: isPresented) {
            guard isPresented else { return }
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            withAnimation { isPresented = false }
        }
    }
}
