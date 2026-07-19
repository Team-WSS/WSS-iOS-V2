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
        logger?.error("탈퇴 확인 화면 서재 통계 로드 실패: \(String(describing: error))")
    }
}
