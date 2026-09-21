//
//  SettingViewModel.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/15/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import Logger
import PushAuthorization

/// 설정 메뉴 목록. 로그아웃·회원탈퇴 등 실제 액션은 하위 화면(`SettingAccountInfoView`)이 처리한다.
/// 유일한 예외가 "알림 설정" 메뉴 — 탭 즉시 시스템 푸시 권한을 확인해야 해서(#193) 이 화면이 직접
/// Action/State를 갖는다(HomeFeature `HomeViewModel.notificationBellTapped`와 반대 순서 —
/// 자세한 이유는 `SettingFeature/CLAUDE.md` 참고).
@MainActor
@Observable
final class SettingViewModel {

    // MARK: - State

    struct State {
        /// "알림 설정" 메뉴를 눌렀는데 시스템 푸시 권한이 denied라 기기 설정 유도 알럿을 띄워야 하는지(#193).
        var isPushAuthorizationAlertPresented = false
        /// 알림 설정 화면으로 이동해도 되는 신호 — `authorized`/`notDetermined`일 때만 메뉴 탭 즉시
        /// 오른다(notDetermined는 시스템 프롬프트 요청 후). **`denied`면 알럿만 띄우고 이동하지 않는다**
        /// — 어느 버튼으로 닫든(사용자 확정) 권한이 없는 채로 그 화면에 들어갈 이유가 없다는 판단.
        /// 권한을 실제로 켜고 오면 "알림 설정" 메뉴를 다시 눌러야 한다(그때는 authorized라 바로 이동).
        var shouldNavigateToNotificationSetting = false
    }

    // MARK: - Action

    enum Action {
        case notificationMenuTapped
        case dismissPushAuthorizationAlert
        case consumeNotificationSettingNavigation
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Dependency

    private let logger: Logger?

    // PushAuthorization
    private let pushAuthorizationChecker: PushAuthorizationChecker

    // MARK: - Init

    init(pushAuthorizationChecker: PushAuthorizationChecker, logger: Logger? = nil) {
        self.pushAuthorizationChecker = pushAuthorizationChecker
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .notificationMenuTapped:                 notificationMenuTapped()
        case .dismissPushAuthorizationAlert:           dismissPushAuthorizationAlert()
        case .consumeNotificationSettingNavigation:    state.shouldNavigateToNotificationSetting = false
        }
    }
}

// MARK: - Action Handling

private extension SettingViewModel {

    /// denied면 이동하지 않고 알럿만 띄운다 — `showWSSAlert`가 `.overlay` 기반이라 이동(push)과 동시에
    /// 띄우면 화면 전환에 밀려 사라지는 것과 별개로, 애초에 권한 없이 그 화면에 들어갈 이유가 없다는
    /// 판단(사용자 확정 — 두 버튼 다 닫기만 하고 이동하지 않는다). notDetermined면 시스템 프롬프트를
    /// 띄운 뒤 이동한다(알럿은 안 띄움).
    func notificationMenuTapped() {
        Task { [weak self] in
            guard let self else { return }
            switch await pushAuthorizationChecker.authorizationStatus() {
            case .authorized:
                state.shouldNavigateToNotificationSetting = true
            case .notDetermined:
                _ = await pushAuthorizationChecker.requestAuthorization()
                state.shouldNavigateToNotificationSetting = true
            case .denied:
                state.isPushAuthorizationAlertPresented = true
            }
        }
    }

    func dismissPushAuthorizationAlert() {
        state.isPushAuthorizationAlertPresented = false
    }
}
