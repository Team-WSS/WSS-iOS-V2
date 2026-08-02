//
//  OnboardingIntroViewModel.swift
//  OnboardingFeature
//
//  Created by Seoyeon Choi on 8/2/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import AuthDomain
import Logger

@MainActor
@Observable
final class OnboardingIntroViewModel {

    // MARK: - State

    struct State {
        var isLoggingIn = false
        /// 로그인 성공 시점에 채워진다 — View는 이 값이 nil이 아니게 되면 완료 콜백을 발화한다.
        var needOnboarding: NeedOnboarding?
        var hasLoginError = false
    }

    // MARK: - Action

    enum Action {
        case loginStarted
        case login(SocialLoginCredential)
        case loginFailed
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Dependency

    private let logger: Logger?

    // AuthDomain
    private let socialLoginUseCase: SocialLoginUseCase

    // MARK: - Init

    init(socialLoginUseCase: SocialLoginUseCase, logger: Logger? = nil) {
        self.socialLoginUseCase = socialLoginUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .loginStarted:          state.isLoggingIn = true
        case .login(let credential): login(with: credential)
        case .loginFailed:           presentSDKLoginFailure()
        case .dismissError:          state.hasLoginError = false
        }
    }
}

// MARK: - Action Handling

private extension OnboardingIntroViewModel {
    /// `.loginStarted`가 SDK 호출 직전에 이미 `isLoggingIn`을 세워두므로 여기선 다시 세팅할 필요는 없지만,
    /// `.loginStarted` 없이 바로 `.login`이 들어와도(테스트 등) 안전하도록 재확인 차 그대로 둔다.
    func login(with credential: SocialLoginCredential) {
        state.isLoggingIn = true
        Task { await performLogin(credential) }
    }

    /// Apple/Kakao SDK 자체 실패(사용자 취소 포함) — credential을 못 받아 UseCase까지 못 간 경우.
    func presentSDKLoginFailure() {
        logger?.error("소셜 로그인 SDK 실패(취소 포함)")
        state.isLoggingIn = false
        state.hasLoginError = true
    }
}

// MARK: - UseCase Handling

private extension OnboardingIntroViewModel {
    func performLogin(_ credential: SocialLoginCredential) async {
        do {
            let needOnboarding = try await socialLoginUseCase.execute(credential: credential)
            state.isLoggingIn = false
            state.needOnboarding = needOnboarding
        } catch {
            state.isLoggingIn = false
            presentLoginError(error)
        }
    }
}

// MARK: - Error Mapping

private extension OnboardingIntroViewModel {
    func presentLoginError(_ error: AuthError) {
        logger?.error("소셜 로그인 실패: \(error)")
        state.hasLoginError = true
    }
}
