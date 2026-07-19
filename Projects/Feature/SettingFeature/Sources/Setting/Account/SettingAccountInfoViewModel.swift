//
//  SettingAccountInfoViewModel.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import ProfileDomain
import AuthDomain
import Logger

@MainActor
@Observable
final class SettingAccountInfoViewModel {

    // MARK: - State

    struct State {
        /// 계정정보 화면의 "이메일" 행 표시용. 로드 실패해도 화면을 막지 않고 그냥 안 보이게 둔다
        /// (탈퇴/로그아웃 등 다른 액션은 이메일 없이도 항상 가능해야 함).
        var email: String?
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
        case load
        case presentLogoutAlert
        case cancelLogout
        case confirmLogout
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false

    // MARK: - Dependency

    private let logger: Logger?

    // ProfileDomain
    private let loadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase

    // AuthDomain
    private let logoutUseCase: LogoutUseCase

    // MARK: - Init

    init(
        loadAccountInfoDraftUseCase: LoadAccountInfoDraftUseCase,
        logoutUseCase: LogoutUseCase,
        logger: Logger? = nil
    ) {
        self.loadAccountInfoDraftUseCase = loadAccountInfoDraftUseCase
        self.logoutUseCase = logoutUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
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
    func load() {
        guard !hasLoaded else { return }
        Task { await loadEmail() }
    }

    func confirmLogout() {
        state.isLogoutAlertPresented = false
        guard !state.isLoggingOut else { return }
        Task { await logout() }
    }
}

// MARK: - UseCase Handling

private extension SettingAccountInfoViewModel {
    /// 이메일은 부가 정보라, 로드에 실패해도 화면을 막지 않고 그냥 안 보이게 둔다.
    func loadEmail() async {
        do {
            state.email = try await loadAccountInfoDraftUseCase.execute().email
            hasLoaded = true
        } catch {
            logger?.error("계정정보 이메일 로드 실패: \(String(describing: error))")
        }
    }

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
