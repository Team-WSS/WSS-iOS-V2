//
//  NotificationSettingViewModel.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import NotificationDomain
import Logger

@MainActor
@Observable
final class NotificationSettingViewModel {

    // MARK: - State

    struct State {
        var isNotificationOn = false
        var isLoading = false
        /// 최초 로드 실패(의미값). 전체화면 `NetworkErrorView` 표시용 — 토글 실패와 분리한다.
        /// 하나로 합치면 토글 실패 시에도 화면 전체가 에러로 뒤덮여, 이미 로드된 목록으로 되돌아올 방법이 없어진다.
        var loadError: NotificationStatusError?
        /// 토글(저장) 실패(의미값). 토스트 표시용 — 화면은 그대로 두고 값만 이전으로 되돌린다.
        var toastError: NotificationStatusError?
    }

    /// 사용자에게 표시할 에러의 **의미값**. 카피·표현(토스트 타입)은 View가 결정한다.
    enum NotificationStatusError: Equatable {
        case unknown
    }

    // MARK: - Action

    enum Action {
        case load
        case toggleNotificationOn(Bool)
        case dismissToast
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false

    // MARK: - Dependency

    private let logger: Logger?

    // NotificationDomain
    private let loadPushPreferenceUseCase: LoadPushPreferenceUseCase
    private let updatePushPreferenceUseCase: UpdatePushPreferenceUseCase

    // MARK: - Init

    init(
        loadPushPreferenceUseCase: LoadPushPreferenceUseCase,
        updatePushPreferenceUseCase: UpdatePushPreferenceUseCase,
        logger: Logger? = nil
    ) {
        self.loadPushPreferenceUseCase = loadPushPreferenceUseCase
        self.updatePushPreferenceUseCase = updatePushPreferenceUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .toggleNotificationOn(let isOn):
            toggle(isOn)
        case .dismissToast:
            state.toastError = nil
        }
    }
}

// MARK: - Action Handling

private extension NotificationSettingViewModel {
    func load() {
        guard !hasLoaded else { return }
        state.isLoading = true
        state.loadError = nil
        Task { await loadNotificationStatus() }
    }

    /// 토글은 즉시 반영(낙관적 업데이트)하고, 실패하면 이전 값으로 되돌린다.
    func toggle(_ isOn: Bool) {
        let previous = state.isNotificationOn
        state.isNotificationOn = isOn
        Task { await updateNotificationStatus(isOn: isOn, previous: previous) }
    }
}

// MARK: - UseCase Handling

private extension NotificationSettingViewModel {
    func loadNotificationStatus() async {
        defer { state.isLoading = false }

        do {
            let pushPreference = try await loadPushPreferenceUseCase.execute()
            state.isNotificationOn = pushPreference.isEnabled
            hasLoaded = true
        } catch {
            presentLoadError(error)
        }
    }

    func updateNotificationStatus(isOn: Bool, previous: Bool) async {
        do {
            try await updatePushPreferenceUseCase.execute(pushPreference: PushPreference(isEnabled: isOn))
        } catch {
            state.isNotificationOn = previous
            presentToastError(error)
        }
    }
}

// MARK: - Error Mapping

private extension NotificationSettingViewModel {
    func presentLoadError(_ error: Error) {
        logger?.error("NotificationSetting 로드 실패: \(String(describing: error))")
        state.loadError = .unknown
    }

    func presentToastError(_ error: Error) {
        logger?.error("NotificationSetting 예기치 못한 에러: \(String(describing: error))")
        state.toastError = .unknown
    }
}
