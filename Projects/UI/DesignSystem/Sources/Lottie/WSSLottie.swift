//
//  WSSLottie.swift
//  DesignSystem
//
//  Created by WonsunLee on 5/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Lottie

public enum WSSLottie {
    public static let loading: LottieAnimation?           = .named("loading",           bundle: .module)
    /// 온보딩 완료(계약 완료) 화면의 두루마리 애니메이션 — 구 파일명 `scroll`은 쓰임을 드러내지
    /// 못해 실제 용도로 다시 이름 붙였다(#178).
    public static let onboardingComplete: LottieAnimation? = .named("onboardingComplete", bundle: .module)
}
