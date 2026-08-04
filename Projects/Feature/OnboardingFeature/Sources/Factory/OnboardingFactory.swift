//
//  OnboardingFactory.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/2/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import AuthDomain
import SettingDomain
import Logger

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 internal로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
///
/// 이름을 `makeView`가 아니라 `makeXxxView`로 두는 이유: 온보딩 플로우는 인트로·가입약관 시트에
/// 이어 닉네임·성별/출생년도·장르 선택 화면이 후속 이슈에서 추가되며, 그때마다 `makeXxxView`가 더 늘어난다.
public enum OnboardingFactory {

    /// - Parameters:
    ///   - onLoginSucceeded: 소셜 로그인 성공 시 발화(`NeedOnboarding`으로 신규/기존 유저 분기).
    ///     화면 전환(다음 온보딩 단계로 진행할지, 바로 홈으로 보낼지)은 호출자(App 조정 계층)가 결정한다.
    @MainActor
    public static func makeIntroView(
        socialLoginUseCase: SocialLoginUseCase,
        logger: Logger? = nil,
        onLoginSucceeded: @escaping (NeedOnboarding) -> Void
    ) -> some View {
        OnboardingIntroView(
            viewModel: OnboardingIntroViewModel(
                socialLoginUseCase: socialLoginUseCase,
                logger: logger
            ),
            onLoginSucceeded: onLoginSucceeded
        )
    }

    /// 온보딩 2단계 — 가입약관 동의 시트. 호출자가 `.sheet`로 띄운다(`interactiveDismissDisabled` 등
    /// 시트 프레젠테이션 설정은 이 화면이 자체 보유 — `LibrarySortSheet` 관례).
    /// - Parameters:
    ///   - onAgreed: 저장 성공 시 발화. 다음 온보딩 단계(닉네임, 후속 이슈)로 진행할지는 호출자가 결정한다.
    ///   - onAuthenticationRequired: 인증 만료 시 로그인 유도 콜백(로드·저장 등 서버 호출 공통).
    @MainActor
    public static func makeTermsAgreementView(
        loadUseCase: LoadTermsAgreementDraftUseCase,
        saveUseCase: SaveTermsAgreementDraftUseCase,
        logger: Logger? = nil,
        onAgreed: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        TermsAgreementView(
            viewModel: TermsAgreementViewModel(
                loadUseCase: loadUseCase,
                saveUseCase: saveUseCase,
                logger: logger
            ),
            onAuthenticationRequired: onAuthenticationRequired,
            onAgreed: onAgreed
        )
    }
}
