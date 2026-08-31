//
//  BundleAppVersionProviderTests.swift
//  SettingDataTests
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import SettingData
import SettingDomain

@Suite
struct BundleAppVersionProviderTests {

    @Test("번들 버전 문자열을 AppVersion으로 파싱한다")
    func parsesBundleVersionString() {
        let provider = BundleAppVersionProvider(versionString: "1.2.3")

        #expect(provider.currentVersion == AppVersion(major: 1, minor: 2, patch: 3))
    }

    @Test("버전 문자열이 없으면 강제 업데이트가 뜨지 않는 방향으로 폴백한다")
    func missingVersionStringFallsBackToNeverForcing() {
        let provider = BundleAppVersionProvider(versionString: nil)

        let strictPolicy = AppUpdatePolicy(
            minimumVersion: AppVersion(major: 999, minor: 0, patch: 0),
            updateDate: nil
        )

        #expect(strictPolicy.requiresForceUpdate(current: provider.currentVersion) == false)
    }

    @Test("버전 문자열이 깨져 있어도 강제 업데이트가 뜨지 않는 방향으로 폴백한다")
    func malformedVersionStringFallsBackToNeverForcing() {
        let provider = BundleAppVersionProvider(versionString: "not-a-version")

        let strictPolicy = AppUpdatePolicy(
            minimumVersion: AppVersion(major: 999, minor: 0, patch: 0),
            updateDate: nil
        )

        #expect(strictPolicy.requiresForceUpdate(current: provider.currentVersion) == false)
    }
}
