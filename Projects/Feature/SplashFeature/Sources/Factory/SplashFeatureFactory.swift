//
//  SplashFeatureFactory.swift
//  SplashFeature
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import SplashDomain

public enum SplashFeatureFactory {

    /// 스플래시 화면을 만든다. `onFinish`가 부트스트랩 결과를 올리면 라우팅은 호출자(App)가 한다.
    @MainActor
    public static func makeView(
        bootstrapAppUseCase: BootstrapAppUseCase,
        onFinish: @escaping (BootstrapOutcome) -> Void
    ) -> some View {
        SplashView(
            viewModel: SplashViewModel(bootstrapAppUseCase: bootstrapAppUseCase),
            onFinish: onFinish
        )
    }
}
