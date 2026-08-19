//
//  OnboardingFactory.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/2/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import AuthDomain
import ProfileDomain
import SettingDomain
import Logger

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 internal로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
///
/// 이름을 `makeView`가 아니라 `makeXxxView`로 두는 이유: 온보딩 플로우는 인트로·가입약관 시트·
/// 나머지 3단계 컨테이너까지 진입점이 여럿이라 무엇을 만드는지 이름에 넣어야 호출부에서 구분된다.
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
    ///   - onAgreed: 저장 성공 시 발화. 다음 온보딩 단계(나머지 3단계 컨테이너)로 진행할지는 호출자가 결정한다.
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

    /// 온보딩 나머지 3단계(닉네임→성별/출생년도→장르선택)를 한 화면(컨테이너) 안에서 진행한다 —
    /// 공통 진행바가 단계 전환 내내 같은 인스턴스로 유지돼야 부드럽게 애니메이션되기 때문에, 단계별로
    /// 화면을 나눠 push하지 않는다(자세한 이유는 `OnboardingStepFlowView` 문서 참고).
    /// 닉네임·성별/출생년도는 저장 UseCase가 없다 — 로컬 상태만 누적하다가, 마지막(장르 선택)에서
    /// `RegisterProfileUseCase`로 한 번에 등록한다.
    /// - Parameters:
    ///   - onCompleted: 등록 성공 시 발화. 온보딩 종료 후 어디로 갈지(Home 등)는 호출자가 결정한다.
    ///   - onAuthenticationRequired: 인증 만료 시 로그인 유도 콜백(중복확인·등록 등 서버 호출 공통).
    @MainActor
    public static func makeStepFlowView(
        validateNicknameUseCase: ValidateNicknameUseCase,
        registerProfileUseCase: RegisterProfileUseCase,
        logger: Logger? = nil,
        onCompleted: @escaping () -> Void,
        onAuthenticationRequired: @escaping () -> Void
    ) -> some View {
        OnboardingStepFlowView(
            validateNicknameUseCase: validateNicknameUseCase,
            registerProfileUseCase: registerProfileUseCase,
            logger: logger,
            onAuthenticationRequired: onAuthenticationRequired,
            onCompleted: onCompleted
        )
    }
}
