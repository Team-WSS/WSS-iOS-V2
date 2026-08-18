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
import PushAuthorization

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
        /// 시스템 푸시 권한이 거부(denied)돼 있어 기기 설정 유도 알럿(`WSSAlertType.setAppNotification`)을
        /// 띄워야 하는지 — 앱 안의 알림 on/off(`isNotificationOn`)와는 별개로, iOS 자체 권한을 본다(#193).
        var isPushAuthorizationAlertPresented = false
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
        case checkPushAuthorization
        case dismissPushAuthorizationAlert
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

    // PushAuthorization — 서버 저장값(isNotificationOn)과 별개인 iOS 시스템 권한 확인용.
    private let pushAuthorizationChecker: PushAuthorizationChecker

    // MARK: - Init

    init(
        loadPushPreferenceUseCase: LoadPushPreferenceUseCase,
        updatePushPreferenceUseCase: UpdatePushPreferenceUseCase,
        pushAuthorizationChecker: PushAuthorizationChecker,
        logger: Logger? = nil
    ) {
        self.loadPushPreferenceUseCase = loadPushPreferenceUseCase
        self.updatePushPreferenceUseCase = updatePushPreferenceUseCase
        self.pushAuthorizationChecker = pushAuthorizationChecker
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
        case .checkPushAuthorization:
            checkPushAuthorization()
        case .dismissPushAuthorizationAlert:
            state.isPushAuthorizationAlertPresented = false
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

    /// 화면에 재진입할 때마다(뒤로 갔다 다시 들어옴) 확인한다 — 그 사이 기기 설정 앱을 다녀와 권한이
    /// 바뀌었을 수 있어서 load()의 hasLoaded 가드와 달리 1회로 막지 않는다. ⚠️ `onAppear`는 뷰
    /// 생명주기(재-push) 이벤트라, 화면을 나가지 않고 앱 스위처·백 제스처로 설정 앱만 다녀오는
    /// 경우(포그라운드 복귀)는 재발화하지 않는다 — 그 경로까지 잡으려면 `scenePhase` 기반 재확인이 별도로 필요.
    func checkPushAuthorization() {
        Task { await checkPushAuthorizationStatus() }
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

    func checkPushAuthorizationStatus() async {
        switch await pushAuthorizationChecker.authorizationStatus() {
        case .authorized:
            break
        case .notDetermined:
            // 시스템 프롬프트를 직접 띄운다 — denied와 달리 앱에서 다시 물어볼 수 있는 유일한 시점.
            _ = await pushAuthorizationChecker.requestAuthorization()
        case .denied:
            state.isPushAuthorizationAlertPresented = true
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
