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
        /// 사용자가 SDK 로그인 시트를 스스로 취소함 — 에러가 아니므로 토스트를 띄우지 않는다(#257).
        case loginCancelled
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    /// `login(with:)` 재진입 가드용 — `state.isLoggingIn`은 `.loginStarted`가 SDK 호출 직전에
    /// 이미 true로 세워두므로 그 값으로는 "이 Task가 이미 떠 있는지"를 구분할 수 없다.
    private var loginTask: Task<Void, Never>?

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
        case .loginCancelled:        cancelSDKLogin()
        case .dismissError:          state.hasLoginError = false
        }
    }
}

// MARK: - Action Handling

private extension OnboardingIntroViewModel {
    /// `.loginStarted`가 SDK 호출 직전에 이미 `isLoggingIn`을 세워두므로 여기선 다시 세팅할 필요는 없지만,
    /// `.loginStarted` 없이 바로 `.login`이 들어와도(테스트 등) 안전하도록 재확인 차 그대로 둔다.
    /// `loginTask`가 이미 떠 있으면(중복 콜백 등) 새 Task를 띄우지 않는다 — View의 `.disabled(isLoggingIn)`에만
    /// 기대지 않고 VM 스스로 재진입을 막는다(`NovelReviewViewModel.save()`의 `guard !state.isSaving` 관례와 동일).
    func login(with credential: SocialLoginCredential) {
        guard loginTask == nil else { return }
        state.isLoggingIn = true
        loginTask = Task {
            await performLogin(credential)
            loginTask = nil
        }
    }

    /// Apple/Kakao SDK 자체 실패(진짜 오류) — credential을 못 받아 UseCase까지 못 간 경우.
    /// 사용자 취소는 여기가 아니라 `cancelSDKLogin()`으로 분기된다(#257 — 취소는 에러 토스트를 띄우지 않음).
    func presentSDKLoginFailure() {
        logger?.error("소셜 로그인 SDK 실패")
        state.isLoggingIn = false
        state.hasLoginError = true
    }

    /// 사용자가 소셜 로그인 시트를 스스로 취소함 — 정상 흐름이라 에러 토스트를 띄우지 않고 로딩만 해제한다(#257).
    func cancelSDKLogin() {
        logger?.info("소셜 로그인 사용자 취소")
        state.isLoggingIn = false
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
