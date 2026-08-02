//
//  OnboardingFactory.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/2/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import AuthDomain
import Logger

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 internal로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
///
/// 이름을 `makeView`가 아니라 `makeIntroView`로 둔 이유: 온보딩 플로우는 후속 이슈에서
/// 가입약관 시트·닉네임·성별/출생년도·장르 선택 화면이 추가되며, 그때 `makeXxxView`가 더 늘어난다.
public enum OnboardingFactory {

    /// - Parameters:
    ///   - onLoginSucceeded: 소셜 로그인 성공 시 발화(`NeedOnboarding`으로 신규/기존 유저 분기).
    ///     화면 전환(다음 온보딩 단계로 진행할지, 바로 홈으로 보낼지)은 호출자(App 조정 계층)가 결정한다.
    ///   - onContinueWithoutSignIn: "회원가입 없이 둘러보기" 탭 시 발화. 도메인 로직 없는 순수 네비게이션 신호라
    ///     `onLoginSucceeded`와 동일하게 화면 전환 판단은 호출자에게 위임한다.
    @MainActor
    public static func makeIntroView(
        socialLoginUseCase: SocialLoginUseCase,
        logger: Logger? = nil,
        onLoginSucceeded: @escaping (NeedOnboarding) -> Void,
        onContinueWithoutSignIn: @escaping () -> Void
    ) -> some View {
        OnboardingIntroView(
            viewModel: OnboardingIntroViewModel(
                socialLoginUseCase: socialLoginUseCase,
                logger: logger
            ),
            onLoginSucceeded: onLoginSucceeded,
            onContinueWithoutSignIn: onContinueWithoutSignIn
        )
    }
}
