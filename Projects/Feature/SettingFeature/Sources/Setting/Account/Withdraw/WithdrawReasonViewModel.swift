//
//  WithdrawReasonViewModel.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import AuthDomain
import Logger

@MainActor
@Observable
final class WithdrawReasonViewModel {

    // MARK: - State

    struct State {
        var draft = WithdrawalReasonDraft()
        var isSubmitting = false
        var shouldDismiss = false
        /// 표시할 에러(의미값). 토스트 문구·아이콘 매핑은 View가 한다(얇은 ViewModel).
        var presentedError: WithdrawError?
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호(Feature 공통 계약).
        /// 탈퇴 401은 이미 세션이 끝난 것이라 실패 토스트 대신 이 신호로 로그인/온보딩으로 되돌린다.
        var requiresAuthentication = false
    }

    /// 사용자에게 표시할 에러의 **의미값**. 카피·표현(토스트 타입)은 View가 결정한다.
    enum WithdrawError: Equatable {
        case unknown
    }

    // MARK: - Derived

    /// 탈퇴하기 버튼 활성화 여부. `WithdrawalReasonDraft`가 이미 검증 규칙(사유 선택·기타 사유 텍스트·약관 동의)을 갖고 있다.
    var isSubmittable: Bool { state.draft.isSubmittable }

    // MARK: - Action

    enum Action {
        case selectReason(WithdrawalReasonOption)
        case setCustomReasonText(String)
        case togglePolicyAgreed
        case submit
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Dependency

    private let logger: Logger?

    // AuthDomain
    private let withdrawUseCase: WithdrawUseCase

    // MARK: - Init

    init(withdrawUseCase: WithdrawUseCase, logger: Logger? = nil) {
        self.withdrawUseCase = withdrawUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .selectReason(let option):
            state.draft.setOption(option)
        case .setCustomReasonText(let text):
            state.draft.setCustomReasonText(text)
        case .togglePolicyAgreed:
            state.draft.setPolicyAgreed(!state.draft.policyAgreed)
        case .submit:
            submit()
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension WithdrawReasonViewModel {
    func submit() {
        guard !state.isSubmitting, state.draft.isSubmittable else { return }
        Task { await withdraw() }
    }
}

// MARK: - UseCase Handling

private extension WithdrawReasonViewModel {
    func withdraw() async {
        state.isSubmitting = true
        defer { state.isSubmitting = false }

        do {
            try await withdrawUseCase.execute(draft: state.draft)
            state.shouldDismiss = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension WithdrawReasonViewModel {
    func presentError(_ error: Error) {
        // 탈퇴 401은 세션이 이미 끝난 것 — 실패 토스트 대신 로그인/온보딩으로 되돌린다(Feature 공통 계약).
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("WithdrawReason 예기치 못한 에러: \(String(describing: error))")
        state.presentedError = .unknown
    }

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환(Feature 공통 계약).
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
