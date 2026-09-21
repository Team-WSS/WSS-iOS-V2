//
//  AppUpdatePolicyTests.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import SettingDomain
import SettingDomainTesting
import BaseDomain

@Suite("AppUpdatePolicy")
struct AppUpdatePolicyTests {

    @Test("현재 버전이 최소 버전보다 낮으면 강제 업데이트가 필요하다")
    func requiresForceUpdateWhenCurrentIsLower() {
        let policy = AppUpdatePolicy(
            minimumVersion: AppVersion(major: 1, minor: 0, patch: 0),
            updateDate: nil
        )

        let current = AppVersion(major: 0, minor: 9, patch: 9)
        #expect(policy.requiresForceUpdate(current: current) == true)
    }

    @Test("현재 버전이 최소 버전과 같으면 강제 업데이트가 필요하지 않다")
    func doesNotRequireForceUpdateWhenCurrentEqualsMinimum() {
        let policy = AppUpdatePolicy(
            minimumVersion: AppVersion(major: 1, minor: 0, patch: 0),
            updateDate: nil
        )

        let current = AppVersion(major: 1, minor: 0, patch: 0)
        #expect(policy.requiresForceUpdate(current: current) == false)
    }

    @Test("현재 버전이 최소 버전보다 높으면 강제 업데이트가 필요하지 않다")
    func doesNotRequireForceUpdateWhenCurrentIsGreater() {
        let policy = AppUpdatePolicy(
            minimumVersion: AppVersion(major: 1, minor: 0, patch: 0),
            updateDate: nil
        )

        let current = AppVersion(major: 1, minor: 0, patch: 1)
        #expect(policy.requiresForceUpdate(current: current) == false)
    }
}
