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

/// 설정 메뉴 목록. 로그아웃·회원탈퇴 등 실제 액션은 하위 화면(`SettingAccountInfoView`)이 처리하고,
/// 이 화면은 메뉴 항목 나열과 하위 화면 전환만 담당해 별도 Action 없이 상태만 노출한다.
@MainActor
@Observable
final class SettingViewModel {

    // MARK: - State

    struct State {

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
}
