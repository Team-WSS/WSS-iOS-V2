//
//  SettingAccountInfoViewModel.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import AuthDomain
import Logger

@MainActor
@Observable
final class SettingAccountInfoViewModel {

    // MARK: - State

    struct State {
        var isLogoutAlertPresented = false
        var isLoggingOut = false
        /// 로그아웃 성공 신호. 세션 종료(로그인 화면 전환 등)는 App(세션 관찰) 책임이라
        /// 이 화면은 성공 신호만 View를 거쳐 호출자에게 전달한다.
        var logoutSucceeded = false
        /// 표시할 에러(의미값). 토스트 문구·아이콘 매핑은 View가 한다(얇은 ViewModel).
        var presentedError: LogoutError?
    }

    enum LogoutError: Equatable {
        case unknown
    }

    // MARK: - Action

    enum Action {
        case presentLogoutAlert
        case cancelLogout
        case confirmLogout
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Dependency

    private let logger: Logger?

    // AuthDomain
    private let logoutUseCase: LogoutUseCase

    // MARK: - Init

    init(logoutUseCase: LogoutUseCase, logger: Logger? = nil) {
        self.logoutUseCase = logoutUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .presentLogoutAlert:
            state.isLogoutAlertPresented = true
        case .cancelLogout:
            state.isLogoutAlertPresented = false
        case .confirmLogout:
            confirmLogout()
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension SettingAccountInfoViewModel {
    func confirmLogout() {
        state.isLogoutAlertPresented = false
        guard !state.isLoggingOut else { return }
        Task { await logout() }
    }
}

// MARK: - UseCase Handling

private extension SettingAccountInfoViewModel {
    func logout() async {
        state.isLoggingOut = true
        defer { state.isLoggingOut = false }

        do {
            try await logoutUseCase.execute()
            state.logoutSucceeded = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension SettingAccountInfoViewModel {
    func presentError(_ error: Error) {
        logger?.error("로그아웃 실패: \(String(describing: error))")
        state.presentedError = .unknown
    }
}
