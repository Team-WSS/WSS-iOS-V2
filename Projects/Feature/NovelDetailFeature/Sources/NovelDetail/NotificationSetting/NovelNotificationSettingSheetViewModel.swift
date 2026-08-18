//
//  NovelNotificationSettingSheetViewModel.swift
//  NovelDetailFeature
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import NotificationDomain
import Logger

@MainActor
@Observable
final class NovelNotificationSettingSheetViewModel {

    // MARK: - State

    struct State {
        var isCompletionNotificationEnabled = false
        var isHiatusReturnNotificationEnabled = false
        var isLoading = false
        /// 최초 로드 실패(의미값). 토글은 로드 성공 후에만 뜨므로 별도 화면 분기 없이 토스트로만 알린다
        /// (시트가 작아 전체화면 에러 뷰를 둘 자리가 마땅치 않음 — 실패해도 닫고 다시 열면 재시도된다).
        var hasLoadError = false
        /// 토글 서버 반영 중 — 두 토글이 항상 두 값을 함께 PUT하므로, 겹쳐 누르면 먼저 낸 요청의
        /// 응답으로 나중 요청이 덮이는 경합이 생긴다. 진행 중엔 새 토글을 막는다.
        var isSyncing = false
        /// 토글 반영 실패(의미값). 토스트 표시용 — 화면 값은 실패 이전으로 되돌린다.
        var toastError: NovelNotificationSettingError?
    }

    /// 사용자에게 표시할 에러의 **의미값**. 카피·표현(토스트 타입)은 View가 결정한다.
    enum NovelNotificationSettingError: Equatable {
        case unknown
    }

    // MARK: - Action

    enum Action {
        case load
        case toggleCompletionNotification(Bool)
        case toggleHiatusReturnNotification(Bool)
        case dismissToast
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    /// 낙관 반영 직전 스냅샷 — 실패 시 두 값을 통째로 이걸로 되돌린다(진행 중엔 `isSyncing`이
    /// 새 토글을 막아 스냅샷 하나로도 충분).
    private var currentSetting: NovelNotificationSetting {
        NovelNotificationSetting(
            isCompletionNotificationEnabled: state.isCompletionNotificationEnabled,
            isHiatusReturnNotificationEnabled: state.isHiatusReturnNotificationEnabled
        )
    }

    // MARK: - Dependency

    private let novelID: NovelID
    private let logger: Logger?

    // NotificationDomain
    private let loadNotificationSettingUseCase: LoadNovelNotificationSettingUseCase
    private let updateNotificationSettingUseCase: UpdateNovelNotificationSettingUseCase

    // MARK: - Init

    init(
        novelID: NovelID,
        loadNotificationSettingUseCase: LoadNovelNotificationSettingUseCase,
        updateNotificationSettingUseCase: UpdateNovelNotificationSettingUseCase,
        logger: Logger? = nil
    ) {
        self.novelID = novelID
        self.loadNotificationSettingUseCase = loadNotificationSettingUseCase
        self.updateNotificationSettingUseCase = updateNotificationSettingUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .toggleCompletionNotification(let isOn):
            toggleCompletionNotification(isOn)
        case .toggleHiatusReturnNotification(let isOn):
            toggleHiatusReturnNotification(isOn)
        case .dismissToast:
            state.toastError = nil
        }
    }
}

// MARK: - Action Handling

private extension NovelNotificationSettingSheetViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        state.isLoading = true
        state.hasLoadError = false
        loadTask = Task { await loadSetting() }
    }

    func toggleCompletionNotification(_ isOn: Bool) {
        guard !state.isSyncing else { return }
        let rollback = currentSetting
        state.isCompletionNotificationEnabled = isOn
        Task { await sync(rollbackTo: rollback) }
    }

    func toggleHiatusReturnNotification(_ isOn: Bool) {
        guard !state.isSyncing else { return }
        let rollback = currentSetting
        state.isHiatusReturnNotificationEnabled = isOn
        Task { await sync(rollbackTo: rollback) }
    }
}

// MARK: - UseCase Handling

private extension NovelNotificationSettingSheetViewModel {
    func loadSetting() async {
        defer {
            loadTask = nil
            state.isLoading = false
        }

        do {
            let setting = try await loadNotificationSettingUseCase.execute(novelID: novelID)
            state.isCompletionNotificationEnabled = setting.isCompletionNotificationEnabled
            state.isHiatusReturnNotificationEnabled = setting.isHiatusReturnNotificationEnabled
            hasLoaded = true
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("작품 알림 설정 로드 실패: \(String(describing: error))")
            state.hasLoadError = true
        }
    }

    /// PUT은 멱등이라 매번 두 값을 함께 보낸다(서버가 부분 갱신을 지원하지 않음).
    func sync(rollbackTo previous: NovelNotificationSetting) async {
        state.isSyncing = true
        defer { state.isSyncing = false }

        do {
            try await updateNotificationSettingUseCase.execute(novelID: novelID, setting: currentSetting)
        } catch {
            state.isCompletionNotificationEnabled = previous.isCompletionNotificationEnabled
            state.isHiatusReturnNotificationEnabled = previous.isHiatusReturnNotificationEnabled
            logger?.error("작품 알림 설정 변경 실패: \(String(describing: error))")
            state.toastError = .unknown
        }
    }
}
