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
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면
        /// 로드 시작 전 한 프레임 동안 토글이 기본값(둘 다 off)으로 스친다(NovelDetailViewModel과 동일 이유).
        var isLoading = true
        /// 토글 서버 반영 중 — 두 토글이 항상 두 값을 함께 PUT하므로, 겹쳐 누르면 먼저 낸 요청의
        /// 응답으로 나중 요청이 덮이는 경합이 생긴다. 진행 중엔 새 토글을 막는다.
        var isSyncing = false
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호 — 로드/토글 어느 쪽에서
        /// 발생하든 여기로 모이며, View가 `onChange`로 소비한다(NovelDetailViewModel과 동일 패턴).
        var requiresAuthentication = false
        /// 로드 실패/토글 반영 실패(의미값) 공용. 토스트 표시용 — 시트가 작아 전체화면 에러 뷰를 둘 자리가
        /// 마땅치 않아 로드 실패도 토스트로만 알린다(닫고 다시 열면 재시도). 토글 실패는 값을 이전으로 되돌린다.
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
        case disappear
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    /// 시트가 스와이프 등으로 닫히는 중 — 명시적 닫기 버튼이 없어 View의 `.onDisappear`가 신호를 보낸다.
    @ObservationIgnored private var isClosing = false

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
        case .disappear:
            disappear()
        }
    }
}

// MARK: - Action Handling

private extension NovelNotificationSettingSheetViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil, !isClosing else { return }
        state.isLoading = true
        loadTask = Task { await loadSetting() }
    }

    func toggleCompletionNotification(_ isOn: Bool) {
        guard !state.isSyncing, !isClosing else { return }
        let rollback = currentSetting
        state.isCompletionNotificationEnabled = isOn
        // Task 스케줄링 틈새에 두 토글이 동시에 들어와도 가드가 뚫리지 않도록, 스폰 전에 동기로 세운다.
        state.isSyncing = true
        syncTask = Task { await sync(rollbackTo: rollback) }
    }

    func toggleHiatusReturnNotification(_ isOn: Bool) {
        guard !state.isSyncing, !isClosing else { return }
        let rollback = currentSetting
        state.isHiatusReturnNotificationEnabled = isOn
        state.isSyncing = true
        syncTask = Task { await sync(rollbackTo: rollback) }
    }

    /// 시트가 닫히는 중(스와이프 등) — 진행 중인 로드/동기화를 취소한다. 명시적 닫기 액션이 없는
    /// 시트라 `NovelDetailViewModel.close()`의 역할을 `.onDisappear`가 대신한다.
    func disappear() {
        guard !isClosing else { return }
        isClosing = true
        loadTask?.cancel()
        syncTask?.cancel()
    }
}

// MARK: - UseCase Handling

private extension NovelNotificationSettingSheetViewModel {
    func loadSetting() async {
        defer {
            loadTask = nil
            if !isClosing { state.isLoading = false }
        }

        do {
            let setting = try await loadNotificationSettingUseCase.execute(novelID: novelID)
            guard !isClosing, !Task.isCancelled else { return }
            state.isCompletionNotificationEnabled = setting.isCompletionNotificationEnabled
            state.isHiatusReturnNotificationEnabled = setting.isHiatusReturnNotificationEnabled
            hasLoaded = true
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            presentError(error, log: "작품 알림 설정 로드 실패")
        }
    }

    /// PUT은 멱등이라 매번 두 값을 함께 보낸다(서버가 부분 갱신을 지원하지 않음).
    func sync(rollbackTo previous: NovelNotificationSetting) async {
        defer {
            syncTask = nil
            if !isClosing { state.isSyncing = false }
        }

        do {
            try await updateNotificationSettingUseCase.execute(novelID: novelID, setting: currentSetting)
        } catch {
            guard !isClosing, !Task.isCancelled else { return }
            state.isCompletionNotificationEnabled = previous.isCompletionNotificationEnabled
            state.isHiatusReturnNotificationEnabled = previous.isHiatusReturnNotificationEnabled
            presentError(error, log: "작품 알림 설정 변경 실패")
        }
    }
}

// MARK: - Error Mapping

private extension NovelNotificationSettingSheetViewModel {
    /// 인증 만료면 로그인 라우팅 신호로 일원화(개별 토스트 대신), 그 외엔 로그 남기고 토스트로 알린다.
    /// (`NovelDetailViewModel.presentError`/`routeToLoginIfAuthenticationRequired`와 동일 패턴.)
    func presentError(_ error: Error, log message: String) {
        guard (error as? RepositoryError) != .authenticationRequired else {
            state.requiresAuthentication = true
            return
        }
        logger?.error("\(message): \(String(describing: error))")
        state.toastError = .unknown
    }
}
