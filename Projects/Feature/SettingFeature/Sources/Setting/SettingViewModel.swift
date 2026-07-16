//
//  SettingViewModel.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/15/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import SettingDomain
import Logger

/// 설정 메뉴 목록. 약관보기·로그아웃·회원탈퇴는 하위 화면·UseCase 연결 전 TODO — 현재는 목록 골격만 제공한다.
@MainActor
@Observable
final class SettingViewModel {

    // MARK: - State

    struct State {
        
    }

    // MARK: - Action

    enum Action {
        case logoutTapped
        case withdrawTapped
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Dependency

    private let logger: Logger?

    // MARK: - Init

    init(logger: Logger? = nil) {
        self.logger = logger
        self.state = State()
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .logoutTapped:
            logger?.info("로그아웃 탭 — TODO: LogoutUseCase 연결")
        case .withdrawTapped:
            logger?.info("회원탈퇴 탭 — TODO: 회원탈퇴 플로우 연결")
        }
    }
}
