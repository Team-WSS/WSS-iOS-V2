//
//  SplashView.swift
//  SplashFeature
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import SplashDomain
import DesignSystem

// 런치 부트스트랩 동안 보이는 스플래시. 이 화면은 아무 데도 전환하지 않는다 —
// 부트스트랩 결과(BootstrapOutcome)를 onFinish로 올리면 라우팅은 App이 한다.
struct SplashView: View {

    @State private var viewModel: SplashViewModel
    private let onFinish: (BootstrapOutcome) -> Void

    init(viewModel: SplashViewModel, onFinish: @escaping (BootstrapOutcome) -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        content
            .onAppear { viewModel.handle(.load) }
            .onChange(of: viewModel.state.outcome) { _, outcome in
                guard let outcome else { return }
                onFinish(outcome)
            }
    }

    // V1 SplashView 파리티 — 배경 전면 위에,
    // 로고는 "safe area 상단 ~ 워드마크" 사이 공간의 세로 중앙, 워드마크는 safe area 하단 inset 30.
    private var content: some View {
        VStack(spacing: 0) {
            WSSImage.imgSplashIcon.swiftUIImage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            WSSImage.imgSplashType.swiftUIImage
            Spacer().frame(height: 30)
        }
        // 배경은 ZStack 형제가 아니라 background로 — scaledToFill의 오버플로 크기가
        // 레이아웃에 오염되면 하단 워드마크가 화면 밖으로 밀린다(시뮬레이터 실측).
        .background {
            WSSImage.imgSplashBackground.swiftUIImage
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView(
        viewModel: SplashViewModel(bootstrapAppUseCase: PreviewBootstrapAppUseCase()),
        onFinish: { _ in }
    )
}

private struct PreviewBootstrapAppUseCase: BootstrapAppUseCase {
    func execute() async -> BootstrapOutcome { .main(needsTermsAgreement: false) }
}
