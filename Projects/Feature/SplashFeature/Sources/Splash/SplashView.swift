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

    private var content: some View {
        // ③단계(V1 대조)에서 로고·워드마크 레이아웃을 채운다 — 골격은 배경 전면만.
        WSSImage.imgSplashBackground.swiftUIImage
            .resizable()
            .ignoresSafeArea()
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
