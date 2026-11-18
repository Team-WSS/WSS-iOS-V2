//
//  AppUpdatePolicyTests.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import SettingDomain

@Suite("강제 업데이트 판단")
struct AppUpdatePolicyTests {

    private let policy = AppUpdatePolicy(
        minimumVersion: AppVersion(major: 1, minor: 0, patch: 0),
        updateDate: nil
    )

    @Test("앱 버전이 최소 버전보다 낮으면 강제 업데이트가 필요하다")
    func requiresUpdateBelowMinimum() {
        let current = AppVersion(major: 0, minor: 9, patch: 9)

        let requiresUpdate = policy.requiresForceUpdate(current: current)

        #expect(requiresUpdate == true)
    }

    @Test(
        "앱 버전이 최소 버전과 같거나 높으면 강제 업데이트가 필요 없다",
        arguments: [
            AppVersion(major: 1, minor: 0, patch: 0),   // 최소 버전과 딱 같음
            AppVersion(major: 1, minor: 0, patch: 1)    // patch 하나 위
        ]
    )
    func doesNotRequireUpdateAtOrAboveMinimum(current: AppVersion) {
        let requiresUpdate = policy.requiresForceUpdate(current: current)

        #expect(requiresUpdate == false)
    }
}
