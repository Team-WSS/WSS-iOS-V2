//
//  WithdrawConfirmViewModel.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import NovelDomain
import Logger

@MainActor
@Observable
final class WithdrawConfirmViewModel {

    // MARK: - State

    struct State {
        var registeredNovelStats: RegisteredNovelStats?
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호(Feature 공통 계약).
        var requiresAuthentication = false
    }

    // MARK: - Action

    enum Action {
        case load
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    // MARK: - Dependency

    private let loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase
    private let logger: Logger?

    // MARK: - Init

    init(
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        logger: Logger? = nil
    ) {
        self.loadRegisteredNovelStatsUseCase = loadRegisteredNovelStatsUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        }
    }
}

// MARK: - Action Handling

private extension WithdrawConfirmViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        loadTask = Task { await loadRegisteredNovelStats() }
    }
}

// MARK: - UseCase Handling

private extension WithdrawConfirmViewModel {
    /// 탈퇴 화면의 서재 통계는 부가 정보라, 로드에 실패해도 화면을 막지 않고 0으로 표시되게 둔다(탈퇴 액션 자체는 항상 가능해야 함).
    func loadRegisteredNovelStats() async {
        defer { loadTask = nil }
        do {
            state.registeredNovelStats = try await loadRegisteredNovelStatsUseCase.execute()
            hasLoaded = true
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension WithdrawConfirmViewModel {
    func presentError(_ error: Error) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("탈퇴 확인 화면 서재 통계 로드 실패: \(String(describing: error))")
    }

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환(Feature 공통 계약).
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
