//
//  WithdrawFlowView.swift
//  SettingFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import AuthDomain
import NovelDomain
import Logger

/// `WithdrawConfirmView` → `WithdrawReasonView` 체이닝 전용 컨테이너.
/// 두 destination을 `SettingAccountInfoView`가 각각 bool로 들면, Confirm 확인 시 두 bool이
/// 동시에 true가 되어(같은 소스 뷰에서 두 `navigationDestination(isPresented:)`가 함께 활성화) 스택 push가 깨진다.
/// Reason의 트리거를 이 컨테이너(=Confirm이 이미 push된 지점)로 옮겨 순차 push가 되도록 분리한다.
struct WithdrawFlowView: View {

    @State private var isReasonPresented = false

    private let loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase
    private let withdrawUseCase: WithdrawUseCase
    private let logger: Logger?
    private let onWithdrawSuccess: () -> Void
    /// 인증 만료 시 로그인 유도 콜백 — 확인 화면 로드·탈퇴 제출이 401로 막히면 발화. 두 하위 화면에 그대로 흘려보낸다.
    private let onAuthenticationRequired: () -> Void

    init(
        loadRegisteredNovelStatsUseCase: LoadRegisteredNovelStatsUseCase,
        withdrawUseCase: WithdrawUseCase,
        logger: Logger? = nil,
        onWithdrawSuccess: @escaping () -> Void = {},
        onAuthenticationRequired: @escaping () -> Void = {}
    ) {
        self.loadRegisteredNovelStatsUseCase = loadRegisteredNovelStatsUseCase
        self.withdrawUseCase = withdrawUseCase
        self.logger = logger
        self.onWithdrawSuccess = onWithdrawSuccess
        self.onAuthenticationRequired = onAuthenticationRequired
    }

    var body: some View {
        SettingFeatureFactory.makeWithdrawConfirmView(
            loadRegisteredNovelStatsUseCase: loadRegisteredNovelStatsUseCase,
            logger: logger,
            onConfirm: { isReasonPresented = true },
            onAuthenticationRequired: onAuthenticationRequired
        )
        .navigationDestination(isPresented: $isReasonPresented) {
            SettingFeatureFactory.makeWithdrawReasonView(
                withdrawUseCase: withdrawUseCase,
                logger: logger,
                onWithdrawSuccess: onWithdrawSuccess,
                onAuthenticationRequired: onAuthenticationRequired
            )
        }
    }
}
