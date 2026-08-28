//
//  OnboardingRootView.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import AuthDomain
import OnboardingFeature
import ProfileDomain
import SettingDomain

/// 앱 진입 후 첫 화면 — 온보딩 전체 플로우(인트로+소셜로그인 → 가입약관 동의 시트 →
/// 닉네임/성별출생년도/장르선택 3단계 컨테이너)를 `OnboardingFeatureFactory`로 조립해 배선한다.
/// `OnboardingFeature/Demo/OnboardingFeatureDemoApp.swift`의 `.live` 조립을 그대로 따르되,
/// Mock 토글·디버그 로그인 우회 버튼은 뺐다(App은 항상 실서버로 붙는다).
///
/// 이 플로우가 끝나는 두 경로(기존 유저 로그인 / 신규 유저 온보딩 완료) 모두 `onFinished`를 불러
/// 호출자(`ContentView`)가 홈으로 라우팅한다 — 어디로 갈지는 이 화면이 정하지 않는다.
struct OnboardingRootView: View {

    let dependencies: AppDependencies
    let onFinished: () -> Void

    /// 로그인 성공 시 `NeedOnboarding.value == true`(신규 유저)면 세운다 — 가입약관 시트 표시 트리거.
    @State private var isTermsAgreementPresented = false
    /// 약관 동의 완료 시 세운다 — 나머지 3단계 컨테이너 push 트리거.
    @State private var isStepFlowPresented = false

    var body: some View {
        NavigationStack {
            introView
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $isTermsAgreementPresented) {
                    termsAgreementView
                }
                .navigationDestination(isPresented: $isStepFlowPresented) {
                    stepFlowView
                }
        }
    }
}

// MARK: - 1단계: 인트로 + 소셜 로그인

private extension OnboardingRootView {
    var introView: some View {
        OnboardingFeatureFactory.makeIntroView(
            socialLoginUseCase: DefaultSocialLoginUseCase(authRepository: dependencies.authRepository),
            logger: dependencies.logger,
            onLoginSucceeded: handleLoginSucceeded
        )
    }

    func handleLoginSucceeded(_ needOnboarding: NeedOnboarding) {
        dependencies.logger.info("로그인 성공 → NeedOnboarding: \(needOnboarding.value)")
        if needOnboarding.value {
            isTermsAgreementPresented = true
        } else {
            dependencies.logger.info("기존 유저 로그인 → Home 진입")
            syncProfileThenFinish()
        }
    }
}

// MARK: - 2단계: 가입약관 동의 시트

private extension OnboardingRootView {
    var termsAgreementView: some View {
        OnboardingFeatureFactory.makeTermsAgreementView(
            loadUseCase: DefaultLoadTermsAgreementDraftUseCase(repository: dependencies.termsAgreementRepository),
            saveUseCase: DefaultSaveTermsAgreementDraftUseCase(repository: dependencies.termsAgreementRepository),
            logger: dependencies.logger,
            onAgreed: handleTermsAgreed,
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    func handleTermsAgreed() {
        dependencies.logger.info("약관 동의 완료 → 다음 단계(닉네임→성별/출생년도→장르선택)")
        isTermsAgreementPresented = false
        isStepFlowPresented = true
    }
}

// MARK: - 3단계: 닉네임/성별출생년도/장르선택 컨테이너

private extension OnboardingRootView {
    var stepFlowView: some View {
        OnboardingFeatureFactory.makeStepFlowView(
            validateNicknameUseCase: DefaultValidateNicknameUseCase(repository: dependencies.profileRepository),
            registerProfileUseCase: DefaultRegisterProfileUseCase(repository: dependencies.profileRepository),
            logger: dependencies.logger,
            onCompleted: handleOnboardingCompleted,
            onAuthenticationRequired: handleAuthenticationRequired
        )
    }

    func handleOnboardingCompleted() {
        dependencies.logger.info("온보딩 완료 → Home 진입")
        syncProfileThenFinish()
    }
}

// MARK: - 공통: 프로필 동기화 후 Home 진입

private extension OnboardingRootView {
    /// 홈의 "{닉네임}님을 위한 추천글" 섹션은 서버 응답이 아니라 **로컬 캐시**(`UserDefaultsStorage`의
    /// `.nickname`)를 읽는다(`RecommendationData`, `HomeFeature/CLAUDE.md` 참고) — 로그인/온보딩
    /// 완료만으로는 이 캐시가 안 채워지므로, Home으로 넘어가기 직전에 `syncUserBasicInfo()`로 한 번
    /// 채워준다. 실패해도(네트워크 등) 닉네임 없이 "추천글"로만 표시될 뿐 치명적이지 않아 Home 진입
    /// 자체는 막지 않는다.
    func syncProfileThenFinish() {
        Task {
            do {
                try await DefaultSyncUserBasicInfoUseCase(repository: dependencies.profileRepository).execute()
            } catch {
                dependencies.logger.error("사용자 기본 정보 동기화 실패(닉네임 캐시 미갱신): \(error)")
            }
            onFinished()
        }
    }
}

// MARK: - 공통: 인증 만료

private extension OnboardingRootView {
    /// 약관 동의·닉네임 중복확인·프로필 등록 등 인증이 필요한 호출이 401(갱신 실패 포함)로 막히면 발화.
    /// 온보딩 플로우 진입 중 세션이 죽는 경우라 되돌아갈 로그인 화면이 곧 `introView`(스택 최상단) —
    /// Home 이후의 "다른 화면에서 로그인으로 라우팅"과 달리 여기선 진행 중이던 시트/스택을 걷어내는
    /// 정도로 충분하다(진짜 재로그인 유도는 화면이 자연히 인트로로 돌아가면서 이뤄짐).
    func handleAuthenticationRequired() {
        dependencies.logger.info("인증 만료 → 로그인 화면으로 복귀")
        isStepFlowPresented = false
        isTermsAgreementPresented = false
    }
}
